require 'jsonb_accessor'

class Pick < ActiveRecord::Base
  jsonb_accessor :data,
    result: :string,
    locked: [:boolean, default: false],
    complete: [:boolean, default: false],
    complete_time: :datetime,
    notified: [:boolean, default: false]

  belongs_to :user
  belongs_to :team
  belongs_to :matchup
  has_one :recap, class_name: "GameRecap", foreign_key: :pick_id

  scope :completed, -> { data_where(complete: true) }
  scope :current_completed_picks, -> { data_where(complete: true, complete_time: { before: DateTime.current.end_of_day, after: DateTime.current.beginning_of_day }).data_order(complete_time: :desc ) }
  scope :currently_on, ->(pick) { merge(Pick.pending_results).where(team_id: pick.team_id).where.not(user_id: pick.user_id) }
  scope :recently_completed, -> { data_where(complete: true, notified: false) }
  scope :pending_results, -> { data_where(complete: false, locked: false) }
  scope :in_progress, -> { data_where(complete: false, locked: true) }
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

  def abbrev
    team.name.split(' ')[-1]
  end
end