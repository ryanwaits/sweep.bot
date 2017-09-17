require 'sinatra/sequel'

DB = Sequel.sqlite
DB.create_table :bankrolls do
  primary_key :user_id
  Float :amount
  Integer :risk
end