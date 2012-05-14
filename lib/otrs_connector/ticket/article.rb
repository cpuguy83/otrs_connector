class OTRS::Ticket::Article < OTRS::Ticket
  
  def self.set_accessors(key)
    attr_accessor key.to_sym
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      OTRS::Ticket::Article.set_accessors(name.to_s.underscore)
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
  
  def create(attributes)
    data = { 'TicketID' => attributes[:ticket_id], 'From' => attributes[:email], 'Subject' => attributes[:title], 'Body' => attributes[:body] }
    data['ArticleType'] ||= 'email-external'
    data['UserID'] ||= 1
    data['SenderType'] ||= 'agent'
    data['HistoryType'] ||= 'NewTicket'
    data['HistoryComment'] ||= ' '
    data['ContentType'] ||= 'text/plain'
    params = { :object => 'TicketObject', :method => 'ArticleCreate', :data => data }
    a = connect(params)
    if a.first.nil? then nil else a end
  end
  
  def self.find(id)
    data = { 'ArticleID' => id, 'UserID' => 1 }
    params = { :object => 'TicketObject', :method => 'ArticleGet', :data => data }
    a = connect(params)
    a = Hash[*a].symbolize_keys
    self.new(a)
  end
  
  def self.where(ticket_id)
    data = { 'TicketID' => ticket_id }
    params = { :object => 'TicketObject', :method => 'ArticleIndex', :data => data }
    a = connect(params)
    b = []
    a.each do |c|
      b << find(c)
    end
    OTRS::Relation.new(b)
  end

end