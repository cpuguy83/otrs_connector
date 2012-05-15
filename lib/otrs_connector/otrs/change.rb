class OTRS::Change < OTRS
  
  attr_accessor :change_free_text31, :change_free_key11, :change_free_text49,
  :planned_start_time, :change_free_key47, :change_free_key28, :change_free_text17,
  :change_free_text3, :change_state_id, :change_free_key25, :create_time,
  :change_free_text29, :change_free_text8, :change_free_text19,
  :change_free_text34, :change_free_text15, :work_order_count, :change_free_text36,
  :change_free_text20, :actual_end_time, :change_free_text5, :change_free_key22,
  :change_free_text10, :justification_plain, :change_state, :change_free_text42,
  :change_free_key15, :change_free_text16, :change_free_key6, :change_free_text47,
  :change_free_key13, :change_free_key50, :change_free_text33, :change_free_key7,
  :change_free_key17, :change_free_key34, :actual_start_time, :change_free_key43,
  :change_free_text9, :change_free_text6, :impact_id, :cab_customers,
  :change_free_key21, :change_free_key39, :change_free_key5, :change_free_text39,
  :change_free_key27, :cab_agents, :change_free_text30, :change_free_key35,
  :change_free_text25, :change_free_text38, :change_free_text23, :change_state_signal,
  :change_free_text41, :change_free_key3, :change_free_text45, :change_free_text1,
  :change_free_text13, :change_free_key31, :accounted_time, :priority_id,
  :change_free_key40, :change_free_text4, :change_free_key4, :change_free_key26,
  :change_free_key42, :change_free_key23, :change_free_key30, :change_free_key36,
  :planned_end_time, :change_free_key49, :change_free_key32, :change_free_text48,
  :change_free_text28, :work_order_i_ds, :change_free_key20, :change_free_text14,
  :change_free_key29, :change_free_text7, :change_free_text27, :change_free_text18,
  :change_number, :planned_effort, :change_free_key37, :change_free_text11, :justification,
  :impact, :change_free_key41, :change_free_text22, :change_free_key10,
  :change_free_key19,
  :create_by,
  :change_free_text50,
  :change_time,
  :change_free_key44,
  :change_free_text21,
  :category_id,
  :change_free_key12,
  :change_free_text43,
  :description_plain,
  :change_free_key14,
  :category,
  :change_free_key16,
  :change_free_text35,
  :change_free_text46,
  :change_id,
  :change_free_key2,
  :change_by,
  :change_free_text2,
  :change_free_key45,
  :change_free_key8,
  :requested_time,
  :change_free_key24,
  :change_free_text37,
  :change_free_key18,
  :change_free_key38,
  :priority,
  :change_free_text26,
  :change_manager_id,
  :change_free_text12,
  :change_free_key48,
  :change_free_key33,
  :change_free_text44,
  :change_free_key1,
  :change_builder_id,
  :change_free_key46,
  :change_free_key9,
  :change_title,
  :change_free_text40,
  :change_free_text24,
  :change_free_text32,
  :description
  
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
    data = attributes
    params = { :object => 'ChangeObject', :method => 'ChangeAdd', :data => data }
    a = connect(params)
    id = a.first
    a = self.class.find(id)
    attributes = a.attributes
    attributes.each do |key,value|
      instance_variable_set "@#{key.to_s}", value
    end
  end
    
  def self.find(id)
    data = { 'ChangeID' => id, 'UserID' => 1 }
    params = { :object => 'ChangeObject', :method => 'ChangeGet', :data => data }
    self.object_preprocessor connect(params)
  end
  
    
    
  
  def self.where(attributes)
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize] = value      #Copies ruby style keys to camel case for OTRS
    end
    data = tmp
    params = { :object => 'ChangeObjectCustom', :method => 'ChangeSearch', :data => data }
    a = connect(params).flatten
    results = self.superclass::Relation.new
    a.each do |c|
      results << self.new(c)
    end
    results
  end
  
  def update_attributes(attributes)
    tmp = {}
    attributes.each do |key,value|
      tmp[key.to_s.camelize] = value      #Copies ruby style keys to camel case for OTRS
    end
    tmp['ChangeID'] = @change_id
    data = tmp
    params = { :object => 'ChangeObject', :method => 'ChangeUpdate', :data => data }
    a = connect(params)
    if a.first.nil?
      nil
    else
      return self
    end
  end
  
  def self.all
    self.where(:name => '%')
  end
  
  def destroy
    id = @change_id
    if self.class.find(id)
      data = { 'ChangeID' => id, 'UserID' => 1 }
      params = { :object => 'ChangeObject', :method => 'ChangeDelete', :data => data }
      connect(params)
      "ChangeID #{id} deleted"
    else
      raise "NoSuchChangeID #{id}"
    end
  end
  
  def id
    self.change_id
  end
  
  def work_order_count
    self.work_order_i_ds.count
  end
  
  def work_orders
    self.class::WorkOrder.where(:ChangeIDs => [self.id])
  end
  
  def status
    self.change_state
  end
  
  def name
    self.change_title
  end
end