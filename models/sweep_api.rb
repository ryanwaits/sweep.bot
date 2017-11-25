require 'json'
require 'httparty'

class SweepApi
  include HTTParty
  base_uri 'https://db76aae9.ngrok.io/api/v1'

  # def initialize(service, page)
  #   @options = { query: { site: service, page: page } }
  # end

  def get_current_picks
    response = self.class.get("/users/1/picks")
    body = JSON.parse(response.body)
    body['current_picks']
  end

  def get_status
    response = self.class.get("/users/1")
    body = JSON.parse(response.body)
    return {
      current_streak: body['user']['history']['current_streak'],
      current_picks: body['user']['current_picks']
    }
  end

  def set_matchup_details id
    response = self.class.get("/matchups/#{id}")
    body = JSON.parse(response.body)
  end

end