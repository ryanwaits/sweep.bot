class MatchupDetail < ActiveRecord::Base
  belongs_to :matchup

  def hot_or_not_details pick
    matchup.home_team.name == pick.team.name ? home_hot_or_not_details : away_hot_or_not_details
  end

  def public_betting_details pick
    matchup.home_team.name == pick.team.name ? home_public_betting_details : away_public_betting_details
  end

  def friend_details pick
    matchup.home_team.name == pick.team.name ? home_friend_details : away_friend_details
  end

end