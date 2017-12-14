namespace :nfl do

desc "Select Picks Reminder"
task :reminder do
  menu = [
    {
      content_type: 'text',
      title: 'Select Picks',
      payload: 'SELECT_PICKS'
    },
    {
      content_type: 'text',
      title: 'Main Menu',
      payload: 'MAIN_MENU'
    }
  ]

  User.with_reminders.each do |user|
    if user.upcoming_picks.length == 0
      puts "Sending reminders to #{user}..."
      text = "It doesn't look like you've made any of your picks for this week... 😕\n\nBut it's ok, you've still got time! ⏳\n\nGet started below 👇\n\n"
      message_options = {
        messaging_type: "UPDATE",
        recipient: { id: user.facebook_uuid },
        message: {
          text: text, 
          quick_replies: menu
        }
      }
      Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
    end
  end
end

desc "Send Notifications"
  task :send_notification do
    puts "Looking for notifications to send...#{Time.now}\n\n"
    menu = [
      {
        content_type: 'text',
        title: 'Current Status',
        payload: 'STATUS'
      },
      {
        content_type: 'text',
        title: 'Select Picks',
        payload: 'SELECT_PICKS'
      },
      {
        content_type: 'text',
        title: 'Friends Status',
        payload: 'FRIENDS_STATUS'
      }
    ]

    picks = Pick.recently_completed
    picks.each do |pick| 
      # For a win
      if pick.result == 'W'
        text = "The #{pick.abbrev} (#{symbol}#{pick.spread}) beat the #{pick.opponent.abbrev} #{pick.matchup.winner_score}-#{pick.matchup.loser_score}."
        if pick.user.recap_all
          emoji = "🔥"
          wins = pick.user.current_streak == 1 ? "win" : "wins"
          symbol = pick.spread > 0 ? "+" : ""
          message_options = {
            messaging_type: "UPDATE",
            recipient: { id: pick.user.facebook_uuid },
            message: {
              text: "#{text}\n\n#{emoji} You now have #{pick.user.current_streak} #{wins} in a row",
              quick_replies: menu
            }
          }
          Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
          puts "Delivered win message..."
        end
        if pick.user.current_streak == 3 && pick.user.recap_win_three
          win_three = "You are 1 win away from a Sweep! 🙏"
          message_options = {
            messaging_type: "UPDATE",
            recipient: { id: pick.user.facebook_uuid },
            message: {
              text: "#{text}\n\n#{emoji} #{win_three}", 
              quick_replies: menu
            }
          }
          Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
          puts "Delivered win message..."
        end

        if pick.user.current_streak == 4 && pick.user.recap_sweep
          sweep = "You hit a Sweep 🔥\n"
          message_options = {
            messaging_type: "UPDATE",
            recipient: { id: pick.user.facebook_uuid },
            message: {
              text: "#{emoji} #{sweep}\n\n#{text}", 
              quick_replies: menu
            }
          }
          Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
          puts "Delivered win message..."
        end
        pick.update_attribute(:notified, true)
      end

      # For a loss
      if pick.result == 'L'
        text = "The #{pick.abbrev} (#{symbol}#{pick.spread}) lost to the #{pick.opponent.abbrev} #{pick.matchup.loser_score}-#{pick.matchup.winner_score}."
        if pick.user.recap_loss
          symbol = pick.spread > 0 ? "+" : ""
          emoji = "❄️"
          # recap = GameRecap.find_by(pick_id: pick.id)
          message_options = {
            messaging_type: "UPDATE",
            recipient: { id: pick.user.facebook_uuid },
            message: {
              text: "#{text}\n\n#{emoji} Your streak is back to 0", 
              quick_replies: menu
            }
          }
          Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
          puts "Delivered loss message..."
        end
        pick.update_attribute(:notified, true)
      end
    end
  end
end