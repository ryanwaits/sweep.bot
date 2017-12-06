require 'jsonb_accessor'

class Pick < ActiveRecord::Base
  jsonb_accessor :data,
    result: :string,
    locked: [:boolean, default: false],
    complete: [:boolean, default: false],
    notified: [:boolean, default: false]

  belongs_to :user
  belongs_to :team
  belongs_to :matchup

  scope :completed, -> { data_where(complete: true) }
  scope :recently_completed, -> { data_where(complete: true, notified: false) }
  scope :pending_results, -> { data_where(complete: false) }
  scope :wins, -> { data_where(result: 'W') }
  scope :losses, -> { data_where(result: 'L') }

  def field
    team.id == matchup.home_team.id ? 'home' : 'away'
  end

  def opponent
    team.id == matchup.home_team.id ? matchup.away_team : matchup.home_team
  end

  def spread
    team.id == matchup.home_team.id ? matchup.point_spread_home : matchup.point_spread_away
  end
end