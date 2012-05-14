class OTRS::Link < OTRS
  
  def self.set_accessors(key)
    attr_accessor key.to_sym
  end
  
  def persisted?
    false
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      OTRS::Link.set_accessors(name.to_s.underscore)
      send("#{name.to_s.underscore.to_sym}=", value)
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
    self.class.create(self.attributes)
  end
  
  def self.create(attributes)
    attributes[:source_object] = attributes[:object1]
    attributes[:target_object] = attributes[:object2]
    attributes[:source_key] = attributes[:key1]
    attributes[:target_key] = attributes[:key2]
    attributes[:state] ||= 'Valid'
    attributes[:user_id] ||= 1
    tmp = {}
    attributes.each do |key,value|
      if key == :user_id
        tmp[:UserID] = value
      end
      tmp[key.to_s.camelize] = value
    end
    data = tmp
    params = { :object => 'LinkObject', :method => 'LinkAdd', :data => data }
    a = connect(params)
    if a.first == "1"
      return self
    else
      nil
    end
  end
  
  def self.where(attributes)
    # Returns list of link objects as Source => Target
    # Haven't decided if I want this to return the link object or what is being linked to
    attributes[:state] ||= 'Valid'
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize.to_sym] = value
    end
    data = tmp
    params = { :object => 'LinkObject', :method => 'LinkKeyList', :data => data }
    a = connect(params)
    a = Hash[*a]
    b = []
    a.each do |key,value|
      c = {}
      c[:key2] = "#{key}"
      c[:object2] = tmp[:Object2]
      c[:object1] = tmp[:Object1]
      c[:key1] = tmp[:Key1]
      b << self.new(c)
    end
    self.superclass::Relation.new(b)
  end

  def destroy
    @type ||= 'Normal'
    data = { :Object1 => @object1, :Key1 => @key1, :Object2 => @object2, :Key2 => @key2, :Type => @type }
    params = { :object => 'LinkObject', :method => 'LinkDelete', :data => data }
    a = connect(params)
    if a.first == 1.to_s
      return true
    else
      return false
    end
  end

end