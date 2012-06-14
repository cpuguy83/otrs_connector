class OTRS::GeneralCatalog < OTRS
  # Really recommend reading OTRS API Documentation for the GeneralCatalog
  
  attr_accessor :name, :change_time, :change_by, :valid_id, :create_time, :item_id, :comment, :create_by
  def self.set_accessor(key)
    attr_accessor key.to_sym
  end
  
  def persisted?
    false
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      self.class.set_accessor(name.to_s.underscore)
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
    self.create(self.attributes)
  end
  
  def self.find(id)
    data = { 'ItemID' => id }
    params = { :object => 'GeneralCatalogObject', :method => 'ItemGet', :data => data }
    a = connect(params)
    unless a.first.nil?
      a = a.first.except('Class') ## Class field is causing issues in Rails
    end
    self.new(a)
  end
  
  def self.item_list(name)
    data = { :Class => name, :Valid => 1 }
    params = { :object => 'GeneralCatalogObject', :method => 'ItemList', :data => data }
    a = connect(params).first
    #b = []
    #unless a.nil?
    #  a.each do |key,value|
    #    b << self.find(key)
    #  end
    #  self.superclass::Relation.new(b)
    #end
  end
  
  def self.item_list_fast(name)
    data = { :Class => name, :Valid => 1 }
    params = { :object => 'GeneralCatalogObject', :method => 'ItemList', :data => data }
    a = connect(params).first
  end
  
  def item_list
    data = { :Class => self.name }
    params = { :object => 'GeneralCatalogObject', :method => 'ItemList', :data => data }
    a = connect(params)
    unless a.nil? then a = a.first end
    b = []
    a.each do |key,value|
      b << self.find(key)
    end
    self.superclass::Relation.new(b)
  end
  
  # Name variable filters the full classlist down so you can get just what you wanted
  def self.class_list(name='')
    data = { }
    params = { :object => 'GeneralCatalogObject', :method => 'ClassList', :data => data }
    items = connect(params).first
    items.collect{ |i| i if i[name] }.compact
  end
  
end