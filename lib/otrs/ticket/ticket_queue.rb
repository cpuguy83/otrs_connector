class OTRS::Ticket::TicketQueue < OTRS::Ticket # Namespace conflict with OTRS::Ticket::Queue
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
  
  def self.all
    data = { 'UserID' => 1 }
    params = { :object => 'QueueObject', :method => 'QueueList', :data => data }
    a = connect(params)
    a = Hash[*a]
    b = []
    a.each do |key,value|
      c = {}
      c[key] = value
      b << c
    end
    c = self.superclass.superclass::Relation.new
    b.each do |d|
      d.each do |key,value|
        tmp = {}
        tmp[:id] = key
        tmp[:name] = value
        c << new(tmp)
      end
    end
    c
  end
  
  def self.all_name
    collection = []
    self.all.each do |s|
      collection << s.name
    end
    return collection
  end

  
end