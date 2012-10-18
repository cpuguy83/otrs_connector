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
      
      def self.find_or_create_session
        if self.session_id
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
          options['SessionID'] = OTRSConnector::API::GenericInterface.find_or_create_session if !options['SessionID']
          raise if !options['SessionID']
          response = self.client.request method do
            soap.body = options
          end
          response = response.to_hash
          raise response.first[1][:error][:error_code] if response.first[1][:error]
          response.first[1]
        end
        
      end
    end
  end
end

require_relative 'generic_interface/session'
require_relative 'generic_interface/ticket'