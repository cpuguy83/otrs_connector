class OTRS::ConfigItem < OTRS
  # I did not convert fields in this classes to underscores because of the wide range of names possible in the OTRS's custom fields for ConfigItems.  In attempting to do so I kept running into issues, even in just our setup, so to KISS I'm just pulling in the fields directly
  
  # Field Names that are part of all ConfigItem objects, not stored in XMLData table
  @@builtin_fields = [:Name,:DeplStateID,:InciStateID,:DefinitionID,
      :CreateTime,:ChangeBy,:ChangeTime,:Class,:ClassID,:ConfigItemID,:CreateBy,:CreateTime,
      :CurDeplState,:CurDeplStateID,:CurDeplStateType,:CurInciState,:CurInciStateID,:CurInciStateType,
      :DeplState,:DeplStateType,:InciState,:InciStateType,:LastVersionID,:Number,:VersionID,:OrderBy,:Limit,:ClassIDs, :InciStateIDs, :DeplStateIDs]
  @@builtin_fields.each do |f|
    attr_accessor f
  end
  
  
  
  def self.set_accessor(key)
    attr_accessor key.to_sym
  end
  
  def persisted?
    false
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      # cannot have numbers at beginning of field name
      unless name =~ /^\d+/ or name =~ / / or name =~ /-/
        self.class.set_accessor(name)
        send("#{name.to_sym}=", value)
      end
    end
  end
  
  def save
    run_callbacks :save do
      self.create
    end
  end
  
  def create
    attributes = self.attributes
    data = { 'ClassID' => self.ClassID, 'UserID' => 1 }
    params = { :object => 'ConfigItemObject', :method => 'ConfigItemAdd', :data => data }
    a = self.class.connect(params)
    attributes[:ConfigItemID] = a.first
    attributes[:XMLData] = self.class.to_otrs_xml(attributes)
    data2 = attributes
    params2 = { :object => 'ConfigItemObject', :method => 'VersionAdd', :data => data2 }
    b = self.class.connect(params2)
    new_version_id = b.first
    config_item = self.class.find(attributes[:ConfigItemID])
    attributes = config_item.attributes
    attributes.each do |key,value|
      instance_variable_set "@#{key.to_s}", value
    end
    config_item
  end
  
  # Converts search hash for search itmes that ar enot the in @@builtin_fields to OTRS XMLData searches
  def self.xml_search(attributes)
    what = []
    attributes.each do |key,value|
      unless @@builtin_fields.include? key
        what << {"[%]{'Version'}[%]{'#{key}'}[%]{'Content'}" => value }
      end
    end
    what
  end
  
  # Custom object processor because of XMLData
  def self.object_preprocessor(object)
    unless object.nil? or object.empty?
      xml = self.from_otrs_xml(object['XMLData'])
      self.new(object.except('XMLData', 'XMLDefinition').merge(xml))
    else
      nil
    end
  end
  
  # Find by ConfigItemID
  def self.find(id)
    data = { 'ConfigItemID' => id, 'XMLDataGet' => 1 }
    params = { :object => 'ConfigItemObjectCustom', :method => 'VersionGet', :data => data }
    object = self.object_preprocessor (connect(params).first)
    object.run_callbacks :find do
      object
    end
  end
  
  # Find by Version ID
  def self.find_version(id)
    data = { 'VersionID' => id, 'XMLDataGet' => 1 }
    params = { :object => 'ConfigItemObject', :method => 'VersionGet', :data => data }
    object = self.object_preprocessor (connect(params).first)
    object.run_callbacks :find do
      object
    end
  end
  
  def self.where(attributes)
    tmp = {}
    tmp['What'] = self.xml_search(attributes)
    attributes.each do |key,value|
      if @@builtin_fields.include? key
        tmp[key.to_s.camelize.to_sym] = value
      end
    end
    data = tmp
    params = { :object => 'ConfigItemObjectCustom', :method => 'ConfigItemSearchExtended', :data => data }
    a = connect(params)
    results = self.superclass::Relation.new
    a.each do |b|
      b.each do |c|
        results << self.object_preprocessor(c)
      end
    end
    results
  end
  
  # Get history of CI object, returns as CI's... may want to create a new class, subclassed from this one called ConfigItemHistoryEntry, or some such, but this works for now.
  def get_history
    data = { :ConfigItemID => self.id, 'XMLDataGet' => 1 }
    params = { :object => 'ConfigItemObjectCustom', :method => 'VersionList', :data => data }
    a = OTRS.connect(params).flatten
    b = self.class.superclass::Relation.new
    a.each do |c|
      b << self.class.object_preprocessor(c)
    end
    return b
  end
  
  
  # Convert non-builtin fields to OTRS's XMLData structure
  def self.to_otrs_xml(attributes)
    xml = attributes.except(:Name,:DeplStateID,:InciStateID,:DefinitionID,
      :CreateTime,:ChangeBy,:ChangeTime,:Class,:ClassID,:ConfigItemID,:CreateBy,:CreateTime,
      :CurDeplState,:CurDeplStateID,:CurDeplStateType,:CurInciState,:CurInciStateID,:CurInciStateType,
      :DeplState,:DeplStateType,:InciState,:InciStateType,:LastVersionID,:Number,:VersionID, :service, :Service)
    xml_hash = {}
    xml_data = [nil, { 'Version' => xml_hash }]
    tmp = []
    xml.each do |key,value|
      key = key.to_s
      tmp << key
    end
    # Order keys properly so they are parsed in the correct order
    tmp.sort! { |x,y| x <=> y }
    tmp.each do |key|
      # In some cases we created special field names because there were multiple fields with the same name.  Fields with the "__" are these special fields and need to be handled specially
      keys = key.split(/__/)
      xml_key = keys[0]
      unless keys[1].nil? then tag_key = keys[1].gsub(/^0/,'').to_i + 1 end
      xml_subkey = keys[2]
      case key
      when /^[aA-zZ]+__0\d+__[aA-zZ]+__0\d+$/
        if xml_hash[xml_key][tag_key][xml_subkey].nil?
          xml_hash[xml_key][tag_key][xml_subkey] = [nil, { "Content" => xml[key.to_sym] }]
        else
          xml_hash[xml_key][tag_key][xml_subkey] << { "Content" => xml[key.to_sym] }
        end
      when /^[aA-zZ]+__0\d+__[aA-zZ]$/
        xml_hash[xml_key][tag_key][xml_subkey] = xml[key.to_sym]
      when /^[aA-zZ]+__0\d+$/
        if xml_hash[xml_key].nil?
          xml_hash[xml_key] = [nil] 
        end
        xml_hash[xml_key] << { "Content" => xml[key.to_sym] }
      when /^[aA-zZ]+__[aA-zZ]$/
        xml_hash[xml_key][1][xml_subkey] = xml[key.to_sym]
      when /^[aA-zZ]+$/
        xml_hash[xml_key] = [ nil, { "Content" => xml[key.to_sym] }]
      end
    end
    xml_data
  end
  
  def update_attributes(updated_attributes)
    run_callbacks :update do
      self.attributes.each do |key,value|
        if updated_attributes[key].nil?
          updated_attributes[key] = value
        end
      end
      updated_attributes[:XMLData] = self.class.to_otrs_xml(updated_attributes)
      xml_attributes = self.attributes.except(:Name,:DeplStateID,:InciStateID,:DefinitionID,
        :CreateTime,:ChangeBy,:ChangeTime,:Class,:ClassID,:ConfigItemID,:CreateBy,:CreateTime,
        :CurDeplState,:CurDeplStateID,:CurDeplStateType,:CurInciState,:CurInciStateID,:CurInciStateType,
        :DeplState,:DeplStateType,:InciState,:InciStateType,:LastVersionID,:Number,:VersionID)
      xml_attributes.each do |key,value|
        updated_attributes = updated_attributes.except(key)
      end
      data = updated_attributes
      params = { :object => 'ConfigItemObject', :method => 'VersionAdd', :data => data }
      a = self.class.connect(params)
      new_version_id = a.first
      data2 = { 'VersionID' => new_version_id }
      params2 = { :object => 'ConfigItemObject', :method => 'VersionConfigItemIDGet', :data => data2 }
      b = self.class.connect(params2)
      config_item = self.class.find(b.first)
      attributes = config_item.attributes
      attributes.each do |key,value|
        instance_variable_set "@#{key.to_s}", value
      end
      config_item
    end
  end
  
  
  # Convert OTRS XMLData structure to our object structure
  def self.from_otrs_xml(xml)
    # OTRS Allows multiples of the same field name.  To handle this, and to make sure we pull all the fields these fields are being handled specially.  Fields with __keyname__count are these fields
    xml = xml[1].flatten[1][1].except("TagKey")
    data = {}
    xml.each do |key,value|
      xml[key].delete(xml[key][0])
      count = xml[key].count
      if count == 1
        data[key] = value[count - 1]["Content"]
        count2 = value[count -1].except("Content","TagKey").count
        if count2 >= 1
          value[count - 1].except("Content","TagKey").each do |key2,value2|
            value2.delete(value2[0])
            data["#{key}__#{key2}"] = value2[0]["Content"]
          end
        end
      else
        while count != 0
          data["#{key}__0#{count - 1}"] = value[count - 1]["Content"]
          count3 = value[count - 1].except("TagKey").count
          if count3 > 1
            value[count - 1].except("Content","TagKey").each do |key3,value3|
              value3.delete(value3[0])
              count4 = value3.count
              if count4 > 1
                while count4 != 0
                  unless value3[count4 - 1]["Content"].nil?
                    data["#{key}__0#{count - 1}__#{key3}__0#{count4 - 1}"] = value3[count4 - 1]["Content"]
                  end
                  count4 = count4 - 1
                end
                
              else
                data["#{key}__0#{count - 1}__#{key3}"] = value3[0]["Content"]
              end
            end
          end
          count = count - 1
        end
      end
    end
    data
  end
  
end