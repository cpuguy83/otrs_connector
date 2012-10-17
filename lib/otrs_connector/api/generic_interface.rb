module OTRSConnector
  module API
    module GenericInterface
      mattr_accessor :session_id, :login_user, :login_password, :default_wsdl_endpoint, :default_wsdl
      self.default_wsdl = ''
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          extend Savon::Model
          include ActivAttr::Model
          extend ActiveModel::Callbacks
          define_model_callbacks :create, :update, :destroy, :find


          self.wsdl ||= OTRS::API::GenericInterface.default_wsdl
          self.wsdl_endpoint ||= OTRS::API::GenericInterface.default_wsdl_endpoint

          client.wsdl.document = self.wsdl
          client.wsdl.endpoint = self.wsdl_endpoint
        end
      end

      def self.create_session
        OTRS::API::GenericInterface::Session.new(user: self.login_user, password: self.login_password)
      end

      module ClassMethods
        attr_accessor :wsdl, :wsdl_endpoint
      end
    end
  end
end