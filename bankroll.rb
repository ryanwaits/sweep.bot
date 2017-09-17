require './db'

class Bankroll < Sequel::Model

end

bankrolls = DB.from(:bankrolls)
bankrolls.insert(user_id: 1, amount: 1000.0, risk: 1)
br = Bankroll.first

puts br