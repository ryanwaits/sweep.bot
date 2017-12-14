class Team < ActiveRecord::Base
  def abbrev
    name.split(' ')[-1]
  end
end