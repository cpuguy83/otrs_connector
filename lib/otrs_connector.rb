#require 'rubygems'
#require 'require_all'
#require 'active_support/json'
#require 'active_model'
#require 'savon'
#require_rel 'otrs_connector'

require 'otrs_connector/api'
require 'otrs_connector/api/generic_interface'
module OTRSConnector

  def self.root
    File.expand_path('../..', __FILE__)
  end
  
  #require "#{self.root.to_s}/lib/otrs_connector/api"
end