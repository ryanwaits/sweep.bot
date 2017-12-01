require 'json'
require 'httparty'
require './user.rb'

class SweepApi
  include HTTParty
  # base_uri 'https://dcfe6d83.ngrok.io/api/v1'

  # def initialize(service, page)
  #   @options = { query: { site: service, page: page } }
  # end


  def find_or_create_user facebook_uuid
    user = User.find_or_create_by_facebook_uuid(facebook_uuid)
  end

end