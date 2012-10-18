module OTRSConnector
  module API
    module GenericInterface
      class Ticket
        include OTRSConnector::API::GenericInterface
        
        class << self
          # Create some extra instance class instance accessors for create/update methods
          attr_accessor :default_history_type, :default_history_comment, :search_method
        end
        self.wsdl = OTRSConnector::API::GenericInterface.default_wsdl
        self.wsdl_endpoint = OTRSConnector::API::GenericInterface.default_wsdl_endpoint
        self.search_method = 'TicketSearch'
        actions 'TicketGet', 'TicketCreate', 'TicketUpdate', 'TicketSearch'
        
        attribute :id, type: Integer
        attribute :age, type: Integer
        attribute :archive_flag
        attribute :change_by, type: Integer
        attribute :changed
        attribute :create_by, type: Integer
        attribute :create_unix_time, type: Integer
        attribute :created
        attribute :customer_id
        attribute :customer_user_id
        attribute :escalation_response_time, type: Integer
        attribute :escalation_solution_time, type: Integer
        attribute :group_id, type: Integer
        attribute :closed
        attribute :escalation_time, type: Integer
        attribute :escalation_update_time, type: Integer
        attribute :first_lock, type: Integer
        attribute :lock
        attribute :lock_id, type: Integer
        attribute :owner
        attribute :owner_id, type: Integer
        attribute :priority
        attribute :priority_id, type: Integer
        attribute :queue
        attribute :queue_id, type: Integer
        attribute :real_till_time_not_used, type: Integer
        attribute :responsible
        attribute :responsible_id, type: Integer
        attribute :slaid, type: Integer
        attribute :service_id, type: Integer
        attribute :service
        attribute :solution_in_min, type: Integer
        attribute :solution_time
        attribute :ticket_number, type: Integer
        attribute :title
        attribute :type
        attribute :type_id, type: Integer
        attribute :unlock_timeout, type: Integer
        attribute :until_time, type: Integer
        attribute :dynamic_fields
        attribute :articles
        attribute :state_id, type: Integer
        attribute :state
        attribute :customer_user
        attribute :article
        
        def self.find(id, options={})
          new_options = {}
          options.each do |key,value|
            if value == true
              set_value = 1
            else
              set_value = 0
            end
            # Sets extra options from API for pulling dynamic fields, articles, extended info, and attachments
            case key
            when :dynamic_fields
              new_options['DynamicFields'] = set_value
            when :extended
              new_options['Extended'] = set_value
            when :articles
              new_options['AllArticles'] = set_value
            when :attachments
              new_options['Attachments'] = set_value
            end
          end
          new_options['TicketID'] = id
          response = self.connect('TicketGet', new_options)[:ticket]
          response[:id] = response[:ticket_id]
          
          # Get dynamic fields if any were sent back
          dynamic_fields = build_dynamic_fields_from_ticket_hash(response)
          
          # Article instance gets created separately
          ticket = new response.except(:article)
          ticket.articles = response[:article].collect do |a| 
            a[:id] = a[:article_id]
            Article.new a
          end if options[:articles] == true
          
          ticket.dynamic_fields = dynamic_fields if dynamic_fields.any?
          ticket
        end
        
        # OTRS sends dynamic fields back as normal ticket fields, even though they should be separate
        # Fields come back as DynamicField_X where X is the field name
        # Here we split these out and create instances of the DynamicField class
        def self.build_dynamic_fields_from_ticket_hash(ticket)
          dynamic_fields = []
          ticket.each do |key, value|
            if key =~ /dynamic_field_/ and !value.nil?
              dynamic_fields << { name: key.to_s.gsub('dynamic_field_', ''), value: value }
            end
          end
          dynamic_fields.collect{|f| DynamicField.new f}
        end
        
        # Pass in an extra_options hash to supply your own history_type and history_comment
        # If you want to include Dynamic fields, you must add to ticket.dynamic_fields an array of DynamicField instances
        def save(extra_options={})
          # Get just the dynamic_field attributes to send to OTRS
          new_dynamic_fields = dynamic_fields.collect{|f| {'Name' => f.name, 'Value' => f.value}} if dynamic_fields
          options = {
            'Ticket'          => {
              'Title'         => title,
              'QueueID'       => queue_id,
              'Queue'         => queue,
              'LockID'        => lock_id,
              'Lock'          => lock,
              'TypeID'        => type_id,
              'Type'          => type,
              'ServiceID'     => service_id,
              'Service'       => service,
              'SLAID'         => slaid,
              'StateID'       => state_id,
              'State'         => state,
              'PriorityID'    => priority_id,
              'Priority'      => priority,
              'OwnerID'       => owner_id,
              'Owner'         => owner,
              'ResponsibleID' => responsible_id,
              'Responsible'   => responsible,
              'CustomerUser'  => customer_user
            },
            'Article' => ({
              'ArticleTypeID' => article.article_type_id,
              'ArticleType'   => article.article_type,
              'SenderType'    => article.sender_type,
              'MimeType'      => article.mime_type || 'text/plain',
              'Charset'       => article.charset || 'utf8',
              'From'          => article.from,
              'Subject'       => article.subject,
              'Body'          => article.body,
              'HistoryType'    => extra_options[:history_type] || self.class.default_history_type,
              'HistoryComment' => extra_options[:history_comment] || self.class.default_history_comment
            } if article),
            'DynamicField' => (new_dynamic_fields if dynamic_fields)
          }
          response = self.class.connect 'TicketCreate', options
          # Pull the full new record from OTRS so we can have an ID
          self.attributes = self.class.find(response[:ticket_id], dynamic_fields: true, articles: true).attributes
          self
        end
        
        def update_attributes(updated_attributes={})
          options = { 'TicketID' => id }
          if updated_attributes[:article]
            article = updated_attributes[:article]
            options['Article'] = {
              'ArticleTypeID' => article.article_type_id,
              'ArticleType'   => article.article_type,
              'SenderType'    => article.sender_type,
              'MimeType'      => article.mime_type || 'text/plain',
              'Charset'       => article.charset || 'utf8',
              'From'          => article.from,
              'Subject'       => article.subject,
              'Body'          => article.body,
              'HistoryType'    => self.class.default_history_type,
              'HistoryComment' => self.class.default_history_comment
            }
          end
          if updated_attributes[:dynamic_fields]
            options['DynamicField'] = []
            df_s = updated_attributes[:dynamic_fields]
            df_s.each do |f|
              options['DynamicField'] << { 'Name' => f.name, 'Value' => f.value }
            end
          elsif updated_attributes[:dynamic_field]
            df = updated_attributes[:dynamic_field]
            options['DynamicField'] = { 'Name' => df.name, 'Value' => df.value }
          end
          updated_attributes.except(:article, :dynamic_fields, :dynamic_field).each do |key, value|
            options['Ticket'] = {} unless options['Ticket']
            options['Ticket'][key.to_s.camelize] = value
          end
          response = self.class.connect 'TicketUpdate', options
          updated_ticket = self.class.find(response[:ticket_id], dynamic_fields: true, articles: true)
          self.attributes = updated_ticket.attributes
          true
        end

        def self.where(attributes)
          Query.new(self).where(attributes)
        end
        
      end
    end
  end
end
require_relative 'ticket/article'
require_relative 'ticket/dynamic_field'