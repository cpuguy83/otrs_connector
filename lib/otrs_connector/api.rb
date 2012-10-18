module OTRSConnector
  module API
    # These get used as the default login users for either iPhoneHandle or the GI
    mattr_accessor :login_user, :login_password
  end
end
require_relative 'api/generic_interface'