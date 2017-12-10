require 'facebook/messenger'
require 'sinatra/activerecord'

require './lib/text_message'
require './lib/attachment_message'
require './lib/payload'

require './models/matchup'
require './models/matchup_detail'
require './models/user'
require './models/pick'
require './models/team'
require './models/sport'

include Facebook::Messenger

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Facebook::Messenger::Profile.set({
  get_started: {
    payload: 'GET_STARTED_PAYLOAD'
  }
}, access_token: ENV['ACCESS_TOKEN'])

Facebook::Messenger::Profile.set({
  persistent_menu: [
    {
      locale: 'default',
      composer_input_disabled: true,
      call_to_actions: [
        {
          type: 'web_url',
          title: 'Leaderboard',
          url: 'http://www.playsweep.com/',
          webview_height_ratio: 'tall'
        },
        {
          type: 'postback',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          type: 'web_url',
          title: 'How To Play',
          url: 'http://www.playsweep.com/',
          webview_height_ratio: 'tall'
        }
      ]
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])

def media(options, menu=nil)
  message_options = {
    messaging_type: "RESPONSE",
    recipient: { id: @user.facebook_uuid },
    message: { 
      attachment: {
        type: 'template',
        payload: {
          template_type: 'open_graph',
          elements: options
        }
      },
      quick_replies: menu
    }
  }

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])

  wait_for_user
end

def say(options, menu=nil)  
  message_options = {
    messaging_type: "RESPONSE",
    recipient: { id: @user.facebook_uuid },
    message: { 
      attachment: {
        type: 'template',
        payload: {
          template_type: 'generic',
          elements: options
        }
      },
      quick_replies: menu
    }
  }

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])

  wait_for_user
end

def quick_reply(text, menu)
  message_options = {
    messaging_type: "RESPONSE",
    recipient: { id: @user.facebook_uuid },
    message: {
      text: text, 
      quick_replies: menu
    }
  }
  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
  wait_for_user
end

def start
  wait_for_user
end

def text_reply recipient_id, message, menu
  TextMessage.new(recipient_id, message, menu).format
end

def set_matchup_details(picks)
  @menu = []
  picks.each do |current_pick|
    symbol = current_pick.spread > 0 ? "+" : ""
    @menu.push(
      {
        content_type: "text",
        title: "#{current_pick.team.name.split(' ')[-1]} (#{symbol}#{current_pick.spread})",
        payload: "MATCHUP_#{current_pick.matchup_id}_PAYLOAD"
      }
    )
  end
  @menu.push({content_type: 'text',title: 'Main Menu', payload: 'MAIN_MENU'})
  @menu
end

def wait_for_user

  Bot.on :postback do |postback|
    @user = User.find_or_create_by(facebook_uuid: postback.sender['id'])

    if postback.payload == 'GET_STARTED_PAYLOAD'
      text = "Welcome to Sweep! 🎉\n\nEvery week, Sweep sends you a select list of games. Make your picks and enjoy the games with nothing but upside! 👌"
      quick_reply(text, GET_STARTED)
    end

    if postback.payload == 'Get Alerts'
      text = "We have alerts you can manage if you want more or less from us during the day.\n\nTap the options below to get started! 👇"
      quick_reply(text, GET_ALERTS)
    end

  end

  Bot.on :message do |message|
    @user = User.find_or_create_by(facebook_uuid: message.sender['id'])
    matchup_id = message.quick_reply.split('_')[1].to_i if message.quick_reply.include?("MATCHUP")
    set_matchup_details(@user.upcoming_picks)

    if message.quick_reply == 'Get Alerts'
      text = "We have alerts you can manage if you want more or less from us during the day.\n\nTap the options below to get started! 👇"
      quick_reply(text, GET_ALERTS)
    end

    if message.text == 'Reminders'
      @user.reminders ? current_preference = "ON" : current_preference = "OFF"
      @user.reminders ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "REMINDERS_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We will remind you when you haven't made any picks for the week.\n\nWe currently have your reminders set to #{current_preference}.\n\nTap below to update your preference ⏰"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'REMINDERS_ON'
      @user.update_attribute(:reminders, true)
      @user.reminders ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Reminders to #{current_preference} 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'REMINDERS_OFF'
      @user.update_attribute(:reminders, false)
      @user.reminders ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Reminders to #{current_preference} 👋"
      quick_reply(text, menu)
    end

    if message.text == 'Props'
      @user.props ? current_preference = "ON" : current_preference = "OFF"
      @user.props ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "PROPS_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We wanted to give you a little more action each week, so we added the option to challenge your friends to some Props.\n\nWe currently have your notifications set to #{current_preference}.\n\nTap below to update your preference 💪"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'PROPS_ON'
      @user.update_attribute(:props, true)
      @user.props ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Props to #{current_preference} 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'PROPS_OFF'
      @user.update_attribute(:props, false)
      @user.props ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Props to #{current_preference} 👋"
      quick_reply(text, menu)
    end

    if message.text == 'Game Recaps'
      menu = [
        {
          content_type: 'text',
          title: "Every Win",
          payload: "RECAP_ALL"
        },
        {
          content_type: 'text',
          title: "Every Loss",
          payload: "RECAP_LOSS"
        },
        {
          content_type: 'text',
          title: 'Three Wins',
          payload: 'RECAP_THREE_WINS'
        },
        {
          content_type: 'text',
          title: 'A Sweep',
          payload: 'RECAP_SWEEP'
        },
        {
          content_type: 'text',
          title: 'Get Alerts',
          payload: 'Get Alerts'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "When you would like to be notified about your results? 🤔"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'RECAP_ALL'
      @user.recap_all ? preference = "OFF" : preference = "ON"
      @user.recap_all ? current_preference = "ON" : current_preference = "OFF"
      @user.recap_all ? text = "You will currently get a notification for every win.\n\nTap below to update your preference ⏰" : text = "You will currently not get a notification for every win.\n\nTap below to update your preference ⏰"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_ALL_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_LOSS'
      @user.recap_loss ? preference = "OFF" : preference = "ON"
      @user.recap_loss ? current_preference = "ON" : current_preference = "OFF"
      @user.recap_loss ? text = "You will currently get a notification for every loss.\n\nTap below to update your preference ⏰" : text = "You will currently not get a notification for every loss.\n\nTap below to update your preference ⏰"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_LOSS_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_THREE_WINS'
     @user.recap_win_three ? preference = "OFF" : preference = "ON"
     @user.recap_win_three ? current_preference = "ON" : current_preference = "OFF"
     @user.recap_win_three ? text = "You will currently get a notification when you hit 3 wins in a row.\n\nTap below to update your preference ⏰" : text = "You will currently not get a notification when you hit 3 wins in a row.\n\nTap below to update your preference ⏰"
     menu = [
       {
         content_type: 'text',
         title: preference,
         payload: "RECAP_THREE_WIN_#{preference}"
       },
       {
         content_type: 'text',
         title: 'Game Recaps',
         payload: 'GAME_RECAPS'
       },
       {
         content_type: 'text',
         title: 'Main Menu',
         payload: 'MAIN_MENU'
       }
     ]
     quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_SWEEP'
      @user.recap_sweep ? preference = "OFF" : preference = "ON"
      @user.recap_sweep ? current_preference = "ON" : current_preference = "OFF"
      @user.recap_sweep ? text = "You will currently get a notification when you hit a Sweep.\n\nTap below to update your preference ⏰" : text = "You will currently not get a notification when you hit a Sweep.\n\nTap below to update your preference ⏰"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_SWEEP_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      quick_reply(text, menu)
    end

    if message.quick_reply == 'RECAP_ALL_ON'
      @user.update_attribute(:recap_all, true)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We will send you a notification for every win 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_ALL_OFF'
      @user.update_attribute(:recap_all, false)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We will no longer send you a notification for every win 👋"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'RECAP_LOSS_ON'
      @user.update_attribute(:recap_loss, true)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We will send you a notification for every loss 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_LOSS_OFF'
      @user.update_attribute(:recap_loss, false)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We will no longer send you a notification for every loss 👋"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'RECAP_THREE_WIN_ON'
      @user.update_attribute(:recap_win_three, true)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We will send you a notification when you hit 3 wins in a row 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_THREE_WIN_OFF'
      @user.update_attribute(:recap_win_three, false)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We will no longer send you a notification when you hit 3 wins in a row 👋"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'RECAP_SWEEP_ON'
      @user.update_attribute(:recap_sweep, true)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We will send you a notification when you hit a Sweep 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_SWEEP_OFF'
      @user.update_attribute(:recap_sweep, false)
      menu = [
        {
          content_type: 'text',
          title: 'Game Recaps',
          payload: 'GAME_RECAPS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We will no longer send you a notification when you hit a Sweep 👋"
      quick_reply(text, menu)
    end

    if message.text == 'How To Play'
      text = "✅ Each week, we offer 4-5 select matchups.\n\n✅ You can select em' all, or you can skip em' all, whatever you want.\n\n✅ Your job is to maintain consecutive wins.\n\n✅ Hitting 4 in a row is considered a Sweep.\n\nTo learn more about how the prizes work, tap below 👇"
      menu = [
        {
          content_type: 'text',
          title: 'What About Prizes?',
          payload: 'PRIZES'
        },
        {
          content_type: 'text',
          title: 'Select Picks',
          payload: 'SELECT_PICKS'
        }
      ]
      quick_reply(text, menu)
    end

    if message.text == 'What About Prizes?'
      text = "Each game day, we offer a $50 prize pool in the form of an Amazon gift card.\n\n✅ If you are the only one to hit a Sweep for the day, you take home the entire prize pool.\n\n✅ If there are many Sweep's on a given day, you share the prize pool with other winners.\n\n✅ If no one hits a Sweep for the day, the prize pool will rollover (i.e, $50 jumps to $100 for the next day)\n\nNow get started by tapping below! 😁"
      menu = [
        {
          content_type: 'text',
          title: 'Select Picks',
          payload: 'SELECT_PICKS'
        }
      ]
      quick_reply(text, menu)
    end

    if message.text == 'Main Menu'
      text = "Tap below to check your current status, select your picks, or see what your friends are doing 👌"
      quick_reply(text, MAIN_MENU)
    end

    if message.quick_reply == "MATCHUP_#{matchup_id}_PAYLOAD"
      pick = @user.upcoming_picks.find_by_matchup_id(matchup_id)
      pick.field == 'home' ? home_num = Pick.currently_on(pick).count : away_num = Pick.currently_on(pick).count
      hot_or_not = pick.matchup.details.hot_or_not_details(pick)
      public_betting_details = pick.matchup.details.public_betting_details(pick)
      
      if pick.field == 'home'
        players, grammar = home_num == 1 ? ["player", "is"] : ["players", "are"]
        pick.matchup.details.update_attribute(:home_friend_details, "👀 #{home_num} other #{players} on Sweep #{grammar} on the #{pick.team.name.split(' ')[-1]}.")
        friend_details = pick.matchup.details.friend_details(pick)
      else
        players, grammar = away_num == 1 ? ["player", "is"] : ["players", "are"]
        pick.matchup.details.update_attribute(:away_friend_details, "👀 #{away_num} other #{players} on Sweep #{grammar} on the #{pick.team.name.split(' ')[-1]}.")
        friend_details = pick.matchup.details.friend_details(pick)
      end
      
      text = "#{hot_or_not}\n\n#{public_betting_details}\n\n#{friend_details}"
      quick_reply(text, @menu)
    end

    if message.quick_reply == 'SELECT_PICKS'
      text = "Which sport do you wanna start with?"
      menu = [
        {
          content_type: 'text',
          title: 'NFL',
          payload: 'NFL'
        }
        # {
        #   content_type: 'text',
        #   title: 'NCAA',
        #   payload: 'NCAA'
        # }
      ]
      quick_reply(text, menu)
    end

    if message.text == 'NFL'
      menu = [ 
        {
          content_type: 'text',
          title: 'Current Status',
          payload: 'STATUS'
        },
        {
          content_type: 'text',
          title: 'Other Sports',
          payload: 'SELECT_PICKS'
        }
      ]
      pick_card = [
        {
          title: 'Are you ready to make your picks for the NFL?',
          image_url: 'https://i.imgur.com/wGZs0XP.png',
          buttons: [
            {
              type: 'web_url',
              messenger_extensions: true,
              title: "Let's get started 🙌",
              url: "https://18c9b5a6.ngrok.io?id=#{@user.id}&sender_id=#{@user.facebook_uuid}&sport=nfl",
              webview_height_ratio: 'tall'
            }
          ]
        }
      ]
      say(pick_card, menu)
    end

    if message.text == 'NCAA'
      menu = [
        {
          content_type: 'text',
          title: 'My Picks',
          payload: 'SEE_PICKS'
        }, 
        {
          content_type: 'text',
          title: 'Current Status',
          payload: 'STATUS'
        },
        {
          content_type: 'text',
          title: 'Other Sports',
          payload: 'SELECT_PICKS'
        }
      ]
      pick_card = [
        {
          title: 'Select Picks Now',
          image_url: 'https://i.imgur.com/zj346Gb.png',
          buttons: [
            {
              type: 'web_url',
              messenger_extensions: true,
              title: 'Pick Now',
              url: "https://18c9b5a6.ngrok.io?id=#{@user.id}&sender_id=#{@user.facebook_uuid}&sport=ncaa",
              webview_height_ratio: 'tall'
            }
          ]
        }
      ]
      say(pick_card, menu)
    end

    if message.text == 'Current Status'
      if @user.upcoming_picks.empty? && @user.picks_in_progress.empty? && @user.current_completed_picks.empty?
        quick_reply("You have nothing in flight for the day! Get started below 👇", MAIN_MENU)
      else
        status_card = [
          {
            content_type: "text",
            title: "Past History",
            payload: "HISTORY"
          },
          {
            content_type: 'text',
            title: 'Friends Status',
            payload: 'FRIENDS_STATUS'
          }
        ]
        emoji = @user.current_streak >= 1 ? "🔥" : "😤"
        wins = @user.current_streak == 1 ? "win" : "wins"
        symbol = @user.upcoming_picks.first.spread > 0 ? "+" : ""
        teams_in_progress = ""
        current_completed_picks = ""

        in_progress = @user.picks_in_progress.map(&:team).map(&:name).map { |team| team.split(' ')[-1]}

        in_progress.each_with_index do |team, index|
          teams_in_progress.concat(team) and break if in_progress.length == 1
          teams_in_progress.concat("#{in_progress[0]} and #{in_progress[1]}") and break if in_progress.length == 2
          teams_in_progress.concat("and #{team}") and break if index == in_progress.length - 1
          teams_in_progress.concat("#{team}, ")
        end

        @user.current_completed_picks.map do |pick|
          result_emoji = pick.result == "W" ? "✅" : "❌"
          current_completed_picks.concat("#{result_emoji} #{pick.team.name.split(' ')[-1]} (#{pick.result})") and break if @user.current_completed_picks.length == @user.current_completed_picks.length - 1
          current_completed_picks.concat("#{result_emoji} #{pick.team.name.split(' ')[-1]} (#{pick.result})\n\n")
        end

        streak_text = "#{emoji} You have #{@user.current_streak} #{wins} in a row\n\n"
        progress_text = @user.picks_in_progress.any? ? "🚦 The #{teams_in_progress} are in progress now.\n\n" : "🚧 You have no games in progress.\n\n"
        upcoming_text = @user.upcoming_picks.any? ? "👉 Next up is your #{@user.upcoming_picks.first.team.name.split(' ')[-1]} (#{symbol}#{@user.upcoming_picks.first.spread}) going up against the #{@user.upcoming_picks.first.opponent.name.split(' ')[-1]}.\n\n" : "🚧 You do not have any games coming up.\n\n"
        results_text = @user.current_completed_picks.any? ? "👇 Your results so far today\n\n#{current_completed_picks}" : ""
        call_to_action = "Tap your teams below to get more details 👇"

        text = "#{streak_text}#{progress_text}#{upcoming_text}#{results_text}#{call_to_action}"

        quick_reply(text, status_card.concat(@menu))
      end                           
    end

    if message.text == 'Past History'
      menu = [
        {
          content_type: 'text',
          title: 'Current Status',
          payload: 'STATUS'
        },
        {
          content_type: 'text',
          title: 'Friends Status',
          payload: 'FRIENDS_STATUS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
     if @user.completed_picks.length > 0
        text = "Here's what you've got so far...\n\nSweep Count: #{@user.sweep_count}\n\nOverall Record: #{@user.picks.wins.count}-#{@user.picks.losses.count}"
        quick_reply(text, menu)
      else
        text = "It doesn't look like we have a history yet 🤷\n\nCheck back here once you've played a bit more and we'll have some stats for you 😉"
        quick_reply(text, menu)
      end
    end

    # if message.text == 'Video'
    #   menu = [
    #     {
    #       content_type: 'text',
    #       title: 'Current Status',
    #       payload: 'STATUS'
    #     },
    #     {
    #       content_type: "text",
    #       title: "Past History",
    #       payload: "HISTORY"
    #     },
    #     {
    #       content_type: 'text',
    #       title: 'Main Menu',
    #       payload: 'MAIN_MENU'
    #     },
    #     {
    #       content_type: 'text',
    #       title: 'Video',
    #       payload: 'VIDEO'
    #     }
    #   ]

    #   options = [
    #     {
    #        url: "https://vimeo.com/246558223"
    #     }
    #   ]
    #   media(options, menu)
    # end

    if message.text == 'Friends Status'
      menu = [
        {
          content_type: 'text',
          title: 'Current Status',
          payload: 'STATUS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      options = [
        {
          "title":"Refer your friends and earn mulligans!",
          "subtitle":"A mulligan can buy you another shot at hitting 4 consecutive wins.",
          "image_url":"https://i.imgur.com/UDErRSF.png",
          "buttons": [
            {
              "type": "element_share",
              "share_contents": { 
                "attachment": {
                  "type": "template",
                  "payload": {
                    "template_type": "generic",
                    "elements": [
                      {
                        "title": "Sweep",
                        "subtitle": "Hit 4 Consecutive Wins and earn Amazon Cash!",
                        "default_action": {
                          "type": "web_url",
                          "url": "http://www.playsweep.com/"
                        },
                        "buttons": [
                          {
                            "type": "web_url",
                            "url": "http://m.me/PlaySweep", 
                            "title": "Try Out Sweep"
                          }
                        ]
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      ]
      say(options, menu)

      # text = "It looks like you don’t have any friends playing on Sweep yet.\n\nYou can always invite them using the option in our menu below 👇\n\nYou’ll be able to see their picks and compare your records for the ultimate bragging rights! 😎"
      # quick_reply(text, status_card)
    end

  end

end

start