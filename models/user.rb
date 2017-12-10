require 'jsonb_accessor'

class User < ActiveRecord::Base
  jsonb_accessor :data,
    referral_count: [:integer, default: 0],
    mulligan_count: [:integer, default: 0]

  jsonb_accessor :notification_settings,
    reminders: [:boolean, default: true],
    props: [:boolean, default: false],
    recap_all: [:boolean, default: false],
    recap_loss: [:boolean, default: true],
    recap_win_three: [:boolean, default: true],
    recap_sweep: [:boolean, default: true]

  has_many :picks, -> { order(:order) }

  scope :most_streaks, -> { order(streak_count: :desc) }
  scope :streak_of, ->(number) { where(current_streak: number) }

  def completed_picks
    picks.completed
  end

  def current_completed_picks
    picks.current_completed_picks
  end

  def picks_in_progress
    picks.in_progress
  end

  def upcoming_picks
    picks.pending_results
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.most_wins
    all.includes(:picks).sort_by { |user| user.picks.wins.length }.reverse
  end
end