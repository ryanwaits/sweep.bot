require 'rubygems'
require 'sinatra'
require 'active_record'
Dir["./models/*.rb"].each {|file| require file }

# Database Config
# configure :development do
#   set :database, {adapter: 'postgresql',  encoding: 'unicode', database: 'unit_bot_development', pool: 5}
# end

# configure :production do
#   set :database, {adapter: 'postgresql',  encoding: 'unicode', database: 'unit_bot_production', pool: 5}
# end

# ActiveRecord::Base.establish_connection(adapter: 'postgresql',  encoding: 'unicode', database: 'unit_bot_development', pool: 5)

# Talk to Facebook
get '/webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end

get "/" do
  "Nothing to see here"
end
