require 'rubygems'
require 'sinatra'
require 'active_record'
Dir["./models/*.rb"].each {|file| require file }

# Database Config
db = URI.parse(ENV['HEROKU_POSTGRESQL_TEAL_URL'] || "postgres://ddruvjsvaaxbyk:d34dc5d5430747972bdaa15a148ef88e1eeb5379ad751cca9ebb1cfc92709c03@ec2-184-73-189-190.compute-1.amazonaws.com:5432/dfes539af18buu")
ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :host => db.host,
  :username => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)

# Talk to Facebook
get '/api/v1/sweep/webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end

get "/" do
  "Nothing to see here"
end
