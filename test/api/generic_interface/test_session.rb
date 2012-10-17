require 'helper'

module TestOTRSConnector
  module API
    module GenericInterface
      class Session < Test::Unit::TestCase
        def setup
          @session = OTRSConnector::API::GenericInterface::Session.new user: 'user', password: 'password'
        end
  
        should 'have session instance' do
          assert_instance_of(OTRSConnector::API::GenericInterface::Session, @session)
        end
        
        should 'have user' do
          assert_not_nil @session.user
        end
        
        should 'have password' do
          assert_not_nil @session.password
        end
        
        should 'connect to otrs and create otrs session' do
          @session.create
        end
      end
    end
  end
end
