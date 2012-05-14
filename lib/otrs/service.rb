class OTRS::Service# < OTRS
  extend OTRS
  attr_accessor :config_items, :tickets, :cur_inci_state, :valid_id, :service_id, :cur_inci_state_type, :type,
    :cur_inci_state, :create_by, :cur_inci_state_type_from_c_is, :change_time, :change_by, :create_time,
    :criticality, :comment, :criticality, :name_short, :type_id, :name, :parent_id, :cur_inci_state_id,
    :criticality_id

  #def self.set_accessor(key)
  #  attr_accessor key.to_sym
  #end
  
  def persisted?
    false
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      #self.class.set_accessor(name.to_s.underscore)
      send("#{name.to_s.underscore.to_sym}=", value)
    end
  end
  
  def self.find(id)
    data = { 'ServiceID' => id, 'UserID' => 1 }
    params = { :object => 'ServiceObject', :method => 'ServiceGet', :data => data }
    self.object_preprocessor connect(params)
  end
    
  def attributes
    attributes = {}
    self.instance_variables.each do |v|
      attributes[v.to_s.gsub('@','').to_sym] = self.instance_variable_get(v)
    end
    attributes
  end
  
  def save
    self.create(self.attributes)
  end
  
  def create(attributes)
    attributes[:valid_id] ||= 1
    attributes[:user_id] ||= 1
    attributes[:type_id] ||= 1
    attributes[:criticality_id] ||= 3
    tmp = {}
    attributes.each do |key,value|
      if key == :user_id
        tmp[:UserID] = value
      end
      if key == :valid_id
        tmp[:ValidID] = value
      end
      if key == :type_id
        tmp[:TypeID] = value
      end
      if key == :criticality_id
        tmp[:CriticalityID] = value
      end
      if key == :parent_id
        tmp[:ParentID] = value
      end
      if key != :user_id or key != :valid_id or key != :type_id or key != :crticality_id or key != :parent_id
        tmp[key.to_s.camelize.to_sym] = value
      end
    end
    attributes = tmp
    data = attributes
    params = { :object => 'ServiceObject', :method => 'ServiceAdd', :data => data }
    a = connect(params)
    service_id = a.first
    unless service_id.nil?
      self.class.find(service_id)
    else
      raise "Could not create service"
    end
    service = self.class.find(service_id)
    service.attributes.each do |key,value|
      instance_variable_set "@#{key.to_s}", value
    end
    service
  end
  
  def self.where(attributes)
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize.to_sym] = value
    end
    attributes = tmp
    attributes[:UserID] = 1
    data = attributes
    params = { :object => 'ServiceObjectCustom', :method => 'ServiceSearch', :data => data }
    a = connect(params)
    services = self.superclass::Relation.new
    a.each do |service|
      services << self.object_preprocessor(service)
    end
    services
  end
  
  def self.all
    self.where(:name => '%')
  end
  
end