class OTRS::ConfigItem < OTRS
  
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
  
  def attributes
    attributes = {}
    self.instance_variables.each do |v|
      attributes[v.to_s.gsub('@','').to_sym] = self.instance_variable_get(v)
    end
    attributes
  end
  
  def save
    self.create
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
  
  def self.xml_search(attributes)
    what = []
    attributes.each do |key,value|
      unless @@builtin_fields.include? key
        what << {"[%]{'Version'}[%]{'#{key}'}[%]{'Content'}" => value }
      end
    end
    what
  end
  
  def self.object_preprocessor(object)
    unless object.nil? or object.empty?
      xml = self.from_otrs_xml(object['XMLData'])
      self.new(object.except('XMLData', 'XMLDefinition').merge(xml))
    else
      nil
    end
  end
  
  def self.find(id)
    data = { 'ConfigItemID' => id, 'XMLDataGet' => 1 }
    params = { :object => 'ConfigItemObjectCustom', :method => 'VersionGet', :data => data }
    self.object_preprocessor (connect(params).first)
  end
  
  def self.find_version(id)
    data = { 'VersionID' => id, 'XMLDataGet' => 1 }
    params = { :object => 'ConfigItemObject', :method => 'VersionGet', :data => data }
    return self.object_preprocessor (connect(params).first)
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
  
  def self.from_otrs_xml(xml)
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
  
  #def self.from_otrs_xml(xml)
  #  data = { :XMLHash => xml }
  #  params = { :object => 'XMLObject', :method => 'XMLHash2D', :data => data }
  #  a = Hash[*(self.connect(params))]
  #end
  
end