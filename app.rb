require 'rubygems'
require 'sinatra'
require 'sinatra/cross_origin'

require "net/http"
require "net/https"
require "cgi"

require "json"

enable :sessions

configure do
  enable :cross_origin
end

set :allow_origin, :any
set :allow_methods, [:get, :post, :options]

before do
  response.headers['Content-Type'] = 'application/json'
  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'

  @client_id = ENV["APP_ID"]
  @client_secret = ENV["APP_SERET"]

  session[:oauth] ||= {}
end

# Talk to Facebook
get '/api/v1/sweep/webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end

get "/" do
  if session[:oauth][:access_token].nil?
    puts "Access Token is nil"
  else
    
    fb_api = FacebookService.new(session[:oauth][:access_token])
    fb_api.get_me(session[:oauth][:access_token])

    session[:user_id] = @json['id']
    request = Net::HTTP::Get.new "/#{session[:user_id]}/friends?access_token=#{session[:oauth][:access_token]}"
    response = http.request request
    @json = JSON.parse(response.body)
    puts @json.inspect

    # request = Net::HTTP::Get.new "/#{session[:user_id]}?fields=picture&access_token=#{session[:oauth][:access_token]}"
    # response = http.request request
    # @json = JSON.parse(response.body)
    # puts "APP"
    # puts @json.inspect

    # request = Net::HTTP::Get.new "/1328837993906209?fields=first_name,last_name,profile_pic&access_token=#{ENV["ACCESS_TOKEN"]}"
    # response = http.request request
    # @json = JSON.parse(response.body)
    # puts "PAGE"
    # puts @json.inspect
  end
end

get "/request" do
  # redirect "https://graph.facebook.com/oauth/authorize?client_id=#{@client_id}&scope=user_friends,email&redirect_uri=http://localhost:3001/oauth/facebook/callback"
  redirect "https://www.facebook.com/v2.11/dialog/oauth?client_id=#{@client_id}&scope=user_friends,email&redirect_uri=https://www.facebook.com/connect/login_success.html"
end

get "/oauth/facebook/callback" do
  session[:oauth][:code] = params[:code]

  http = Net::HTTP.new "graph.facebook.com", 443
  request = Net::HTTP::Get.new "/oauth/access_token?client_id=#{@client_id}&redirect_uri=http://localhost:3001/oauth/facebook/callback&client_secret=#{@client_secret}&code=#{session[:oauth][:code]}"
  http.use_ssl = true
  response = http.request request

  body = JSON.parse(response.body)
  session[:oauth][:access_token] = body["access_token"]
  session[:oauth][:token_type] = body["token_type"]
  session[:oauth][:expires_in] = body["expires_in"]

  redirect "/"
end


