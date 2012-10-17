#require 'rubygems'

require 'active_support/json'
require 'active_model'
require 'savon'
require 'active_attr'

module OTRSConnector
  def self.root
    File.expand_path('../..', __FILE__)
  end
end

require_relative 'otrs_connector/api'
require_relative 'otrs_connector/relation'