require "net/http"
require "net/https"
require 'json'

class FacebookService
  def initialize facebook_id, access_token
    @facebook_id = facebook_id
    @access_token = access_token
    @http = Net::HTTP.new "graph.facebook.com", 443
    @http.use_ssl = true
  end

  def get_me access_token
    request = Net::HTTP::Get.new("me?access_token=#{@access_token}")
    @response = @http.request(request)
    @json = JSON.parse(response.body)
    @json.inspect
  end
end