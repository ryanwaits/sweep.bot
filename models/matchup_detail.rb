class MatchupDetail < ActiveRecord::Base
  belongs_to :matchup

  def details(pick)
    matchup.home_team.name == pick.team.name ? home_team_description : away_team_description
  end 
end