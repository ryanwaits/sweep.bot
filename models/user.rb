require 'jsonb_accessor'

class User < ActiveRecord::Base
  jsonb_accessor :data,
    referral_count: [:integer, default: 0],
    mulligan_count: [:integer, default: 0]

  has_many :picks, -> { order(:order) }

  scope :most_streaks, -> { order(streak_count: :desc) }
  scope :streak_of, ->(number) { where(current_streak: number) }

  def current_picks
    picks.pending_results
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.most_wins
    all.includes(:picks).sort_by { |user| user.picks.wins.length }.reverse
  end
end