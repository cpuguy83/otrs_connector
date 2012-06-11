class OTRS
  # This class is mostly used for inheritance purposes
  # All subclasses will be able to directly connect to OTRS
  # All subclasses have active_record style callbacks
  
  # Include stuff for calbacks, validations
  include ActiveModel::Conversion
  include ActiveModel::Naming
  include ActiveModel::Validations
  extend ActiveModel::Callbacks

  # Create callbacks on before/after create/save/update
  define_model_callbacks :create, :update, :save

  # api_url is the base URL used to connect to the json api of OTRS, this will be the custom json.pl as the standard doesn't include ITSM module
  @@otrs_api_url ||= "https://loalhost/otrs/json.pl"
  
  # Username / password combo should be an actual OTRS agent defined on the OTRS server
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

  # Convert object's instance variables to a hash
  def attributes
    attributes = {}
    self.instance_variables.each do |v|
      attributes[v.to_s.gsub('@','').to_sym] = self.instance_variable_get(v)
    end
    attributes
  end

  # Handles communication with OTRS
  
  def self.setup_connection_params(params)
    if self.api_url =~ /^https/
      require 'net/https'
    else
      require 'net/http'
    end
    
    base_url = self.api_url
    # Build request URL
    logon = URI.encode("User=#{self.user}&Password=#{self.password}")
    object = URI.encode(params[:object])
    method = URI.encode(params[:method])
    data = params[:data].to_json
    data = URI.encode(data)
    # Had some issues with certain characters not being escaped properly and causing JSON issues
    data = URI.escape(data, '=\',\\/+-&?#.;')
    URI.parse("#{base_url}?#{logon}&Object=#{object}&Method=#{method}&Data=#{data}")
  end
  
  def self.get_from_remote(uri, read_timeout=60)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = read_timeout
    if self.api_url =~ /^https/
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
  end
  
  def self.process_response(response)
    result = ActiveSupport::JSON::decode(response.body)
    if result["Result"] == 'successful'
      return result["Data"]
    else
      raise "Error:#{result["Result"]} #{result["Data"]}"
    end
  end
  
  
  def self.connect(params, timeout=60, retries=4)
    uri = self.setup_connection_params(params)
    retry_counter = 0
    # Connect to OTRS
    begin
    response = self.get_from_remote(uri, timeout)
    rescue EOFError
      retry_counter += 1
      puts "EOFError, Attempt: #{counter+1}"
      retry if retry_counter < retries
      raise EOFError if retry_counter >= retries

    rescue Timeout::Error
      retry_counter += 1
      timeout = timeout*1.5
      puts "Timeout::Error Attempt: #{retry_counter+1}, Timeout #{timeout}"
      retry if retry_counter < retries
      raise Timeout::Error if retry_counter >= retries
    end
    return self.process_response(response)
  end

  # Base method for processing objects returned by OTRS into Ruby objects
  # This works in most cases, but not all, namely with OTRS::ConfigItem due to extra attributes
  def self.object_preprocessor(object)
    unless object.empty? or object.nil?
      a = Hash[*object]
      self.new(a.symbolize_keys)
    else
      raise 'NoSuchObject'
    end
  end

  # Not sure why this is here
  def connect(params)
    self.class.connect(params)
  end
end
