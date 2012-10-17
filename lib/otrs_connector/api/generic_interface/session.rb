module OTRSConnector
  module API
    module GenericInterface
      class Session
        include OTRSConnector::API::GenericInterface
        
        attribute :user
        attribute :password
        attribute :otrs_session_id
        attribute :wsdl_endpoint, default: self.wsdl_endpoint
        attribute :wsdl, default: self.wsdl
        
        def create
          self.run_callbacks :create do
            self.user ||= OTRSConnector::API.login_user
            self.password ||= OTRSConnector::API.login_password
            self.wsdl_endpoint ||= OTRSConnector::API::GenericInterface.default_wsdl_endpoint
            self.wsdl ||= OTRSConnector::API::GenericInterface.default_wsdl
          
            raise 'MissingUser' if !self.user
            raise 'MissingPassword' if !self.password
          
            self.class.client.wsdl.document = self.wsdl
            self.class.client.wsdl.endpoint = self.wsdl_endpoint
          
            response = self.class.client.request 'SessionCreate' do
              soap.body = { 'UserLogin' => self.user, 'Password' => self.password }
            end
            raise response.to_hash[:session_create_response][:error][:error_code] if response.to_hash[:session_create_response][:error]
            self.otrs_session_id = response.to_hash[:session_create_response][:session_id]
            self
          end
        end
      end
    end
  end
end