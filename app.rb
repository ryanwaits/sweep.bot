require 'rubygems'
require 'sinatra'
require 'active_record'
Dir["./models/*.rb"].each {|file| require file }

# Database Config

# ActiveRecord::Base.establish_connection(adapter: 'postgresql',  encoding: 'unicode', url: ENV['HEROKU_POSTGRESQL_TEAL_URL'], pool: 5)

# Talk to Facebook
get '/webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end

get "/" do
  "Nothing to see here"
end
