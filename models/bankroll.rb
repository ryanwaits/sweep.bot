require 'active_record'
require 'sinatra/activerecord'

class Bankroll < ActiveRecord::Base
  belongs_to :user
end