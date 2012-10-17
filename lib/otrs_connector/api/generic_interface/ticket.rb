module OTRSConnector
  module API
    module GenericInterface
      class Ticket
        include OTRSConnector::API::GenericInterface
        self.wsdl = OTRSConnector::API::GenericInterface.default_wsdl
        self.wsdl_endpoint = OTRSConnector::API::GenericInterface.default_wsdl_endpoint
        
        actions 'TicketGet', 'TicketCreate', 'TicketUpdate', 'TicketSearch'
        
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
        
        after_initialize :setup_articles
        after_initialize :setup_dynamic_fields
        
        def self.find(id, options={})
          new_options = {}
          options.each do |key,value|
            if value == true
              set_value = 1
            else
              set_value = 0
            end
          
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
          ticket = new( split_external_keys_from_ticket_hash self.connect('TicketGet', new_options)[:ticket] )
          ticket.send do 'run_callbacks', :find
            ticket
          end
        end
        
        def self.split_external_keys_from_ticket_hash(ticket)
          dynamic_fields = {}
          ticket.each do |key, value|
            if key =~ /^dynamic_field_/
              dynamic_fields[key] == value
              ticket.delete(key)
            elsif key =~ /^ticket_free_(key|text).*\d+/
              ticket.delete(key)
            end
          end
          ticket[:dynamic_fields] = dynamic_fields
          ticket[:articles] = ticket[:article]
          ticket.delete(:article)
          ticket
        end
        
        private
          def setup_dynamic_fields
            self.dynamic_fields = 'stuff'#self.dynamic_fields.collect { |f| DynamicField.new f }
          end
          
          def setup_articles
            self.articles = 'more stuff'#self.articles.collect {|a| Article.new a }
          end
        
      end
    end
  end
end
require_relative 'ticket/article'
require_relative 'ticket/dynamic_field'