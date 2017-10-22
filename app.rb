require 'rubygems'
require 'sinatra'
require 'active_record'
Dir["./models/*.rb"].each {|file| require file }

# Database Config
db = URI.parse(ENV['HEROKU_POSTGRESQL_TEAL_URL'] || "postgres://localhost")
ActiveRecord::Base.establish_connection(
  :adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host => db.host,
  :username => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)

# Talk to Facebook
get '/webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end

get "/" do
  "Nothing to see here"
end
