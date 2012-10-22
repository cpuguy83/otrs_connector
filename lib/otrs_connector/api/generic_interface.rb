module OTRSConnector
  module API
    module GenericInterface
      mattr_accessor :session_id, :default_wsdl_endpoint, :default_wsdl
      self.default_wsdl = "#{OTRSConnector.root}/vendor/otrs.ticket.wsdl"
      
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          extend Savon::Model
          include ActiveAttr::Model
          extend ActiveModel::Callbacks
          
          define_model_callbacks :create, :update, :destroy, :initialize

          self.wsdl ||= OTRSConnector::API::GenericInterface.default_wsdl
          self.wsdl_endpoint ||= OTRSConnector::API::GenericInterface.default_wsdl_endpoint
          
          
          alias_method :initialize_from_active_attr, :initialize
        end
        
      end
      
      # Redefine initialize to add callback
      def intialize(attributes={})
        run_callbacks :initialize do
          initialize_from_active_attr(attributes)
        end
      end
      
      def self.find_or_create_session(force_create=false)
        if self.session_id and force_create == false
          return self.session_id
        else
          @session = OTRSConnector::API::GenericInterface::Session.new(user: OTRSConnector::API.login_user, password: OTRSConnector::API.login_password, wsdl_endpoint: self.default_wsdl_endpoint).create
          return self.session_id = @session.otrs_session_id
        end
      end

      module ClassMethods
        attr_accessor :wsdl, :wsdl_endpoint
        
        # Generic handler for actual communication with OTRS
        def connect(method, options)
          client.wsdl.document = self.wsdl
          client.wsdl.endpoint = self.wsdl_endpoint
          options['SessionID'] = OTRSConnector::API::GenericInterface.find_or_create_session if !options['SessionID'] unless method == 'SessionCreate'
          raise OTRSConnector::API::GenericInterface::NoSessionError if !options['SessionID'] unless method == 'SessionCreate'
          auth_retry_count = 0
          timeout_retry_count = 0
          eof_retry_count = 0
          begin
            response = self.client.request method do
              soap.body = options
            end
            response = response.to_hash
            
            # Check for errors
            if response.first[1][:error]
              error = response.first[1][:error]
              exception_class = "OTRSConnector::API::GenericInterface::#{error[:error_code].split('.')[1]}Error"
              # Check if a custom exception is defined
              if OTRSConnector.class_exists?(exception_class)
                # Raise custom exception
                raise exception_class.constantize, error[:error_message]
              else
                # Raise runtime error if no custom exception
                raise error[:error_code].split('.')[1]
              end
            end
          
          rescue OTRSConnector::API::GenericInterface::AuthFailError
            options['SessionID'] = OTRSConnector::API::GenericInterface.find_or_create_session(true) unless method == 'SessionCreate'
            auth_retry_count += 1
            printf "\n\nAuth Failed, creating new session and trying again\n\n"
            retry if auth_retry_count < 2

          rescue Timeout::Error
            client.http.open_timeout += 50
            client.http.read_timeout += 50
            timeout_retry_count += 1
            retry if timeout_retry_count <= 3
          
          rescue EOFError
            sleep 1
            eof_retry_count += 1
            retry if eof_retry_count <= 4
          end
            
          response.first[1]
        end
        
      end
    end
  end
end

require_relative 'generic_interface/session'
require_relative 'generic_interface/ticket'
require_relative 'generic_interface/query'
require_relative 'generic_interface/exception'