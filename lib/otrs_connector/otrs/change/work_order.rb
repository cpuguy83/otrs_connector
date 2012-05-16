class OTRS::Change::WorkOrder < OTRS

  attr_accessor :work_order_free_key15,
    :accounted_time,
    :work_order_title,
    :instruction_plain,
    :work_order_free_text24,
    :work_order_free_key24,
    :work_order_free_text18,
    :planned_start_time,
    :work_order_free_key7,
    :work_order_free_text2,
    :work_order_free_text22,
    :work_order_free_key33,
    :planned_end_time,
    :work_order_free_key18,
    :work_order_free_key9,
    :work_order_free_text14,
    :work_order_agent_id,
    :work_order_free_text21,
    :work_order_free_text11,
    :work_order_free_text38,
    :create_time,
    :work_order_free_key32,
    :work_order_free_text19,
    :work_order_free_text29,
    :report_plain,
    :work_order_free_key25,
    :work_order_free_text1,
    :work_order_free_key39,
    :work_order_free_text28,
    :work_order_state_id,
    :work_order_free_text27,
    :work_order_free_text37,
    :work_order_free_key14,
    :work_order_free_key31,
    :work_order_free_key36,
    :work_order_free_key43,
    :work_order_free_text40,
    :work_order_free_key19,
    :work_order_free_key1,
    :planned_effort,
    :actual_end_time,
    :work_order_free_text49,
    :work_order_free_key50,
    :work_order_free_key2,
    :instruction,
    :work_order_free_text30,
    :create_by,
    :work_order_state,
    :work_order_free_key21,
    :work_order_free_text8,
    :work_order_free_text47,
    :change_time,
    :work_order_free_key5,
    :work_order_free_text4,
    :work_order_free_key16,
    :work_order_free_text39,
    :work_order_free_text3,
    :work_order_free_key28,
    :work_order_free_text15,
    :work_order_free_key29,
    :work_order_free_text13,
    :work_order_free_key6,
    :work_order_free_text7,
    :work_order_free_text25,
    :work_order_free_text12,
    :work_order_free_text26,
    :work_order_free_key22,
    :work_order_free_text46,
    :work_order_free_key37,
    :actual_start_time,
    :work_order_free_key44,
    :work_order_free_text41,
    :work_order_type_id,
    :work_order_free_key40,
    :work_order_free_key10,
    :work_order_free_text44,
    :change_id,
    :work_order_free_text5,
    :work_order_free_key23,
    :work_order_free_key12,
    :work_order_free_text16,
    :work_order_free_text43,
    :change_by,
    :work_order_state_signal,
    :work_order_free_key27,
    :work_order_free_key17,
    :work_order_free_text42,
    :work_order_free_text34,
    :work_order_free_key47,
    :work_order_free_key35,
    :work_order_free_key4,
    :work_order_id,
    :work_order_free_text6,
    :work_order_free_text48,
    :work_order_free_key41,
    :work_order_free_key30,
    :work_order_free_key26,
    :report,
    :work_order_free_key42,
    :work_order_free_key49,
    :work_order_free_text10,
    :work_order_free_text9,
    :work_order_free_key45,
    :work_order_number,
    :work_order_free_text33,
    :work_order_free_text17,
    :work_order_free_text45,
    :work_order_free_text35,
    :work_order_free_text50,
    :work_order_free_key46,
    :work_order_free_key34,
    :work_order_free_text32,
    :work_order_free_key20,
    :work_order_free_key48,
    :work_order_free_text20,
    :work_order_free_text31,
    :work_order_free_text36,
    :work_order_free_key3,
    :work_order_free_key11,
    :work_order_type,
    :work_order_free_text23,
    :work_order_free_key8,
    :work_order_free_key38,
    :work_order_free_key13



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

  def save
    self.create(self.attributes)
  end
  
  def create(attributes)
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize.to_sym] = value
    end
    attributes = tmp
    attributes[:UserID] = '1'
    attributes[:ChangeID] = attributes[:ChangeId]
    attributes.delete(:ChangeId)
    data = attributes
    params = { :object => 'WorkOrderObject', :method => 'WorkOrderAdd', :data => data }
    a = connect(params)
    id = a.first
    if id.nil?
      nil
    else
      b = self.class.find(id)
      attributes = b.attributes
      attributes.each do |key,value|
        instance_variable_set "@#{key.to_s}", value
      end
      b
    end
  end
  
  def update_attributes(attributes)
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize] = value      #Copies ruby style keys to camel case for OTRS
    end
    tmp['WorkOrderID'] = @work_order_id
    data = tmp
    params = { :object => 'WorkOrderObject', :method => 'WorkOrderUpdate', :data => data }
    a = connect(params)
    if a.first.nil?
      nil
    else
      return self
    end
  end
  
  def self.find(id)
    data = { 'WorkOrderID' => id, 'UserID' => 1 }
    params = { :object => 'WorkOrderObject', :method => 'WorkOrderGet', :data => data }
    self.object_preprocessor connect(params)
  end
  
  def destroy
    id = @change_id
    if self.class.find(id)
      data = { 'ChangeID' => id, 'UserID' => 1 }
      params = { :object => 'WorkOrderObject', :method => 'WorkOrderDelete', :data => data }
      connect(params)
      "WorkOrderID #{id} deleted"
    else
      raise "NoSuchWorkOrderID #{id}"
    end
  end
  
  def self.where(attributes)
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize] = value      #Copies ruby style keys to camel case for OTRS
    end
    data = tmp
    params = { :object => 'WorkOrderObjectCustom', :method => 'WorkOrderSearch', :data => data }
    a = connect(params).flatten
    results = self.superclass::Relation.new
    a.each do |c|
      results << self.new(c)
    end
    results
  end
  
  def change
    self.class.superclass::Change.find(self.change_id)
  end
  
  def name
    self.work_order_title
  end
  
  def title
    self.work_order_title
  end
  
  def id
    self.work_order_id
  end
  
  def status
    self.work_order_status
  end
  
end