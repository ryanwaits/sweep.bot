require 'active_record'
require 'sinatra/activerecord'

class User < ActiveRecord::Base
  has_one :bankroll
end