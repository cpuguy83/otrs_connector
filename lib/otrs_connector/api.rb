module OTRSConnector
  module API
    mattr_accessor :login_user, :login_password
  end
end
require_relative 'api/generic_interface'