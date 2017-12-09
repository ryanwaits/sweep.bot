require 'jsonb_accessor'
require 'time'

class Matchup < ActiveRecord::Base
  CURRENT_WEEK = 12

  jsonb_accessor :data,
    started: [:boolean, default: false],
    final: [:boolean, default: false],
    loser_id: :integer,
    winner_id: :integer,
    loser_score: :integer,
    winner_score: :integer

  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :winner, class_name: "Team", foreign_key: :winner_id, optional: true
  belongs_to :loser, class_name: "Team", foreign_key: :loser_id, optional: true
  belongs_to :sport
  has_one :matchup_detail, class_name: "MatchupDetail", foreign_key: "matchup_id"
  has_many :picks

  # scope :current_week, -> { where(week: CURRENT_WEEK).order(order: :asc) }
  # scope :selected_matchups, -> { joins(:picks).where('picks.user_id = 1') }
  scope :for_nfl, -> { joins(:sport).where('sports.name = ?', 'NFL').order(order: :asc) }
  scope :for_ncaa, -> { joins(:sport).where('sports.name = ?', 'NCAA').order(order: :asc) }
  scope :pending, -> { data_where(started: false) }

  # def self.unselected_matchups
  #   Matchup.current_week - Matchup.selected_matchups
  # end

  def gametime
    Time.new(start_time_year, start_time_month, start_time_day, start_time_hour, start_time_minute)
  end

  def to_date
    gametime.strftime('%A, %B %d, %Y @ %I:%M %p %Z')
  end
end