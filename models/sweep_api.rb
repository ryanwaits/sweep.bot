require 'json'
require 'httparty'

class SweepApi
  include HTTParty
  base_uri 'https://4c9b13d4.ngrok.io/api/v1'

  # def initialize(service, page)
  #   @options = { query: { site: service, page: page } }
  # end

  def get_current_picks
    response = self.class.get("/users/1/picks")
    body = JSON.parse(response.body)
    body['current_picks']
  end

  def get_current_streak
    response = self.class.get("/users/1")
    body = JSON.parse(response.body)
    body['user']['history']['current_streak']
  end

end