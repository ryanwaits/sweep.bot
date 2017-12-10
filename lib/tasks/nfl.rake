namespace :nfl do

desc "Make Picks Reminder"
task :reminder do
  puts "Sending reminders..."
  menu = [
    {
      content_type: 'text',
      title: '👀 My Picks',
      payload: 'SEE_PICKS'
    },
    {
      content_type: 'text',
      title: '🏆 Make Picks',
      payload: 'MAKE_PICKS'
    },
    {
      content_type: 'text',
      title: '🤔 Current Status',
      payload: 'STATUS'
    }
  ]

  users = User.all
  # Add more details with matchup information
  # matchups = Matchup.pending
  users.each do |user|
    if user.upcoming_picks.length == 0
      puts "Remind users to make picks..."
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
    # else
    #   puts "Remind users to make any changes..."
    #   text = "Game time is near! 🏈🏈🏈\n\nIf you need to make any additional changes below, you've still got time 👇\n\n"
    #   message_options = {
    #     messaging_type: "UPDATE",
    #     recipient: { id: user.facebook_uuid },
    #     message: {
    #       text: text, 
    #       quick_replies: menu
    #     }
    #   }
    #   Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
    end
  end
end

desc "Send Notifications"
  task :send_notification do
    puts "Looking for notifications to send..."
    menu = [
      {
        content_type: 'text',
        title: '👀 My Picks',
        payload: 'SEE_PICKS'
      },
      {
        content_type: 'text',
        title: '🏆 Make Picks',
        payload: 'MAKE_PICKS'
      },
      {
        content_type: 'text',
        title: '🤔 Current Status',
        payload: 'STATUS'
      }
    ]

    picks = Pick.recently_completed
    picks.each do |pick| 
      # For a win
      if pick.result == 'W'
        if pick.user.current_streak == 3
          text = "Well done! 🎉\n\nCongrats with the #{pick.try(:team).try(:name)} play!\n\nYou're 1 more win away from a Sweep!"
          message_options = {
            messaging_type: "UPDATE",
            recipient: { id: pick.user.facebook_uuid },
            message: {
              text: text, 
              quick_replies: menu
            }
          }
          Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
          pick.update_attribute(:notified, true)
          puts "Delivered win message..."
        else
          text = "Nice! 🎉\n\nYou got a big win with the #{pick.try(:team).try(:name)}!\n\nYou've got a current streak of #{pick.user.current_streak}!"
          message_options = {
            messaging_type: "UPDATE",
            recipient: { id: pick.user.facebook_uuid },
            message: {
              text: text, 
              quick_replies: menu
            }
          }
          Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
          pick.update_attribute(:notified, true)
          puts "Delivered win message..."
        end
      end

      # For a loss
      if pick.result == 'L'
        text = "Aw shucks 😩, the #{pick.try(:team).try(:name)} came up short today."
        message_options = {
          messaging_type: "UPDATE",
          recipient: { id: pick.user.facebook_uuid },
          message: {
            text: text, 
            quick_replies: menu
          }
        }
        Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
        pick.update_attribute(:notified, true)
        puts "Delivered loss message..."
      end
    end
  end
end