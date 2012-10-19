module OTRSConnector
  module API
    module GenericInterface
      class AuthFailError < StandardError
      end
      
      class NoSessionError < StandardError
      end
    end
  end
end
