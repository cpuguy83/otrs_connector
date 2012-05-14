require 'otrs/service'
require 'otrs/change'
require 'otrs/config_item'
require 'otrs/otrs_general_catalog'
require 'otrs/link'
require 'otrs/relation'
require 'otrs/ticket'
class OTRS
  include ActiveModel::Conversion
  include ActiveModel::Naming
  include ActiveModel::Validations
  extend ActiveModel::Callbacks

  define_model_callbacks :create, :update, :save

  # @@otrs_host is the address where the OTRS server presides
  # api_url is the base URL used to connect to the json api of OTRS, this will be the custom json.pl as the standard doesn't include ITSM module
  @@otrs_api_url ||= "https://loalhost/otrs/json.pl"
  # Username / password combo should be an actual OTRS agent defined on the OTRS server
  # I have not tested this with other forms of OTRS authentication
  @@otrs_user ||= 'rails'
  @@otrs_pass ||= 'rails'

  def self.user
    @@otrs_user
  end
  def self.user=(username)
    @@otrs_user = username
  end

  def self.password
    @@otrs_pass
  end
  def self.password=(password)
    @@otrs_pass = password
  end

  def self.api_url
    @@otrs_api_url
  end
  def self.api_url=(url)
    @@otrs_api_url = url
  end

  def attributes
    attributes = {}
    self.instance_variables.each do |v|
      attributes[v.to_s.gsub('@','').to_sym] = self.instance_variable_get(v)
    end
    attributes
  end

  def self.connect(params)
    require 'net/https'
    base_url = self.api_url
    logon = URI.encode("User=#{self.user}&Password=#{self.password}")
    object = URI.encode(params[:object])
    method = URI.encode(params[:method])
    data = params[:data].to_json
    data = URI.encode(data)
    data = URI.escape(data, '=\',\\/+-&?#.;')
    uri = URI.parse("#{base_url}?#{logon}&Object=#{object}&Method=#{method}&Data=#{data}")
  
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    result = ActiveSupport::JSON::decode(response.body)
    if result["Result"] == 'successful'
      result["Data"]
    else
      raise "Error:#{result["Result"]} #{result["Data"]}"
    end
  end

  def self.object_preprocessor(object)
    unless object.empty? or object.nil?
      a = Hash[*object]
      self.new(a.symbolize_keys)
    else
      raise 'NoSuchObject'
    end
  end


  def connect(params)
    self.class.connect(params)
  end
end
