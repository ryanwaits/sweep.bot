require 'jsonb_accessor'

class User < ActiveRecord::Base
  jsonb_accessor :data,
    referral_count: [:integer, default: 0],
    mulligan_count: [:integer, default: 0]

  jsonb_accessor :notification_settings,
    reminders: [:boolean, default: false],
    props: [:boolean, default: false],
    recap_all: [:boolean, default: false],
    recap_loss: [:boolean, default: true],
    recap_win_three: [:boolean, default: false],
    recap_sweep: [:boolean, default: true]

  has_many :picks, -> { order(:order) }

  scope :with_reminders, -> { notification_settings_where(reminders: true) }
  scope :with_recap_all, -> { notification_settings_where(recap_all: true) }
  scope :with_recap_loss, -> { notification_settings_where(recap_loss: true) }
  scope :with_recap_win_three, -> { notification_settings_where(recap_win_three: true) }
  scope :with_recap_sweep, -> { notification_settings_where(recap_sweep: true) }
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