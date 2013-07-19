class OTRS::Ticket < OTRS
  # Validations aren't working
  validates_presence_of :title, :body, :queue, :state
  #validates_presence_of :email
  before_save :strip_characters_from_body

  attr_accessor :age, :priority_id, :service_id, :ticket_free_text11,
    :ticket_free_time4, :ticket_free_time1, :ticket_free_text6, :state_id,
    :ticket_free_time5, :escalation_time, :ticket_free_time6, :ticket_free_key9,
    :owner_id, :changed, :owner, :ticket_free_text7, :ticket_free_key11, :created,
    :ticket_free_text4, :queue_id, :ticket_free_text2, :ticket_free_key6,
    :ticket_id, :ticket_free_key5, :ticket_free_text12, :escalation_response_time,
    :unlock_timeout, :ticket_free_time3, :archive_flag, :ticket_free_text3,
    :customer_user_id, :ticket_free_text8, :ticket_free_text9, :type,
    :ticket_free_key7, :responsible, :ticket_free_text10, :responsible_id,
    :ticket_free_key16, :ticket_free_key3, :real_till_time_not_used, :group_id,
    :ticket_free_key13, :customer_id, :ticket_free_key1, :type_id, :priority,
    :ticket_free_key12, :ticket_free_key10, :ticket_free_key8, :until_time,
    :ticket_free_text1, :escalation_update_time, :ticket_free_time2, :queue,
    :ticket_free_text13, :state, :title, :ticket_free_text5, :ticket_free_text15,
    :ticket_free_text14, :state_type, :escalation_solution_time, :lock_id,
    :ticket_free_key2, :ticket_number, :ticket_free_key14, :lock,
    :create_time_unix, :ticket_free_key4, :slaid, :ticket_free_key15, :ticket_free_text16,
    :change_by, :create_by
  
  def id
    self.ticket_id
  end
  
  def persisted?
    false
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name.to_s.underscore.to_sym}=", value)
    end
  end
  
  def self.ticket_number_lookup(ticket_id)
    data = { 'TicketID' => ticket_id, 'UserID' => 1 }
    params = { :object => 'TicketObject', :method => 'TicketNumberLookup', :data => data }
    connect(params).first
  end
  
  def save
    run_callbacks :save do
      self.create(self.attributes)
    end
  end
  
  def create(attributes)
    attributes[:type] ||= 'Incident'
    attributes[:state] ||= 'new'
    attributes[:queue] ||= 'Service Desk'
    attributes[:lock] ||= 'unlock'
    attributes[:priority] ||= '3 normal'
    attributes[:user_id] ||= '1'
    attributes[:owner_id] ||= attributes[:user_id]
    tmp = {}
    attributes.each do |key,value|
      if key == :user_id
        tmp[:UserID] = value
      end
      if key == :owner_id
        tmp[:OwnerID] = value
      end
      if key == :customer_id
        tmp[:CustomerID] = value
      end
      if key != :user_id or key != :owner_id or key != :customer_id
        tmp[key.to_s.camelize.to_sym] = value
      end

    end
    attributes = tmp
    data = attributes
    params = { :object => 'TicketObject', :method => 'TicketCreate', :data => data }
    a = connect(params)
    ticket_id = a.first
    article = OTRS::Ticket::Article.new(
      :ticket_id => ticket_id, 
      :body => attributes[:Body], 
      :email => attributes[:Email], 
      :title => attributes[:Title])
    if article.save
      ticket = self.class.find(ticket_id)
      attributes = ticket.attributes
      attributes.each do |key,value|
        instance_variable_set "@#{key.to_s}", value
      end
      ticket
    else
      ticket.destroy
      raise 'Could not create ticket'
    end
  end
  
  def destroy
    id = @ticket_id
    data = { 'TicketID' => id, 'UserID' => 1 }
    params = { :object => 'TicketObject', :method => 'TicketDelete', :data => data }
    connect(params)
    "Ticket ID: #{id} deleted"
  end
  
  def self.find(id)
    data = { 'TicketID' => id, 'UserID' => 1 }
    params = { :object => 'TicketObject', :method => 'TicketGet', :data => data }
    object = self.object_preprocessor(connect(params))
    object.run_callbacks :find do
      object
    end
  end
  def self.search(attributes) 
    #input attributes => https://github.com/OTRS/otrs/blob/rel-3_2/Kernel/System/TicketSearch.pm  
    attributes['Result'] = 'ARRAY'
    data = attributes
    params = { :object => 'TicketObject', :method => 'TicketSearch', :data => data }
    
    return connect(params)[0].to_i
  end
  
  
  
  def self.where(attributes)
    attributes['UserID'] = 1
    attributes['Result'] = 'ARRAY'
    data = attributes
    params = { :object => 'TicketObjectCustom', :method => 'TicketSearch', :data => data }
    a = connect(params)
    results = self.superclass::Relation.new
    a.each do |ticket|
      results << self.object_preprocessor(ticket)  #Add find results to array
    end
    results
  end
  
  def self.free_text_fields(id)
    data = {:UserID => 1, :Type => 'TicketFreeText' + id.to_s}
    params = { :object => 'TicketObject', :method => 'TicketFreeTextGet', :data => data }
    a = self.connect(params).first.symbolize_keys
    #b = []
    #a.each do |key,value|
    #  b << [value,key]
    #end
    #return b
  end
  
  def set_free_text_field(id, key, value)
    data = { :UserID => 1, :Counter => id, :Key => key, :Value => value, :TicketID => self.id }
    params = { :object => 'TicketObject', :method => 'TicketFreeTextSet', :data => data }
    a = self.connect(params)
    if a.first == 1 then return true else return false end
  end
  
  def name
    self.title
  end
  
  private
  def strip_characters_from_body
    self.body.gsub(/\r/,'').gsub(/\n/,'\\n')
  end
end
