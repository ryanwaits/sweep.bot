require 'facebook/messenger'
require 'sinatra/activerecord'

require './lib/text_message'
require './lib/attachment_message'

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
          title: 'Preferences',
          payload: 'PREFERENCES'
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

MAIN_MENU = [
  {
    content_type: 'text',
    title: 'My Picks',
    payload: 'SEE_PICKS'
  },
  {
    content_type: 'text',
    title: 'Select Picks',
    payload: 'SELECT_PICKS'
  },
  {
    content_type: 'text',
    title: 'Current Status',
    payload: 'STATUS'
  }
]

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
    @menu.push(
      {
        content_type: "text",
        title: "#{current_pick.team.name.split(' ')[-1]} (#{current_pick.spread})",
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
      menu = [
        {
          content_type: 'text',
          title: 'How To Play',
          payload: 'HOW_TO_PLAY'
        },
        {
          content_type: 'text',
          title: 'Select Picks',
          payload: 'SELECT_PICKS'
        }
      ]
      text = "Welcome to Sweep! 🎉\n\nEvery week, Sweep sends you a select list of games. Make your picks and enjoy the games with nothing but upside! 👌"
      quick_reply(text, menu)
    end

    if postback.payload == 'PREFERENCES'
      menu = [
        {
          content_type: 'text',
          title: 'Pregame Reminder',
          payload: 'PREGAME_REMINDERS'
        },
        {
          content_type: 'text',
          title: 'Pregame Props',
          payload: 'PREGAME_REMINDERS'
        },
        {
          content_type: 'text',
          title: 'In Game Props',
          payload: 'IN_GAME_UPDATES'
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
      text = "We've got a few preferences you can manage if you want more or less from us during the day.\n\nTap the options below to get started! 👇"
      quick_reply(text, menu)
    end

  end

  Bot.on :message do |message|
    @user = User.find_or_create_by(facebook_uuid: message.sender['id'])
    matchup_id = message.quick_reply.split('_')[1].to_i if message.quick_reply
    set_matchup_details(@user.current_picks)

    if message.quick_reply == 'PREFERENCES'
      menu = [
        {
          content_type: 'text',
          title: 'Pregame Reminder',
          payload: 'PREGAME_REMINDERS'
        },
        {
          content_type: 'text',
          title: 'Pregame Props',
          payload: 'PREGAME_REMINDERS'
        },
        {
          content_type: 'text',
          title: 'In Game Props',
          payload: 'IN_GAME_UPDATES'
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
      text = "We've got a few preferences you can manage if you want more or less from us during the day.\n\nTap the options below to get started! 👇"
      quick_reply(text, menu)
    end

    if message.text == 'Pregame Reminder'
      @user.pregame_reminder ? current_preference = "ON" : current_preference = "OFF"
      @user.pregame_reminder ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "PREGAME_REMINDERS_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We currently have your notifications set to #{current_preference}.\n\nTap below to update your preference ⏰"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'PREGAME_REMINDERS_ON'
      @user.update_attribute(:pregame_reminder, true)
      @user.pregame_reminder ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Pregame Reminder to #{current_preference} 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'PREGAME_REMINDERS_OFF'
      @user.update_attribute(:pregame_reminder, false)
      @user.pregame_reminder ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Pregame Reminder to #{current_preference} 👋"
      quick_reply(text, menu)
    end

    if message.text == 'Pregame Props'
      @user.pregame_props ? current_preference = "ON" : current_preference = "OFF"
      @user.pregame_props ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "PREGAME_PROPS_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We wanted to give you a little more action each week, so we added the option to challenge your friends to some pregame props.\n\nWe currently have your notifications set to #{current_preference}.\n\nTap below to update your preference 💪"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'PREGAME_PROPS_ON'
      @user.update_attribute(:pregame_props, true)
      @user.pregame_props ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Pregame Props to #{current_preference} 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'PREGAME_PROPS_OFF'
      @user.update_attribute(:pregame_props, false)
      @user.pregame_props ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your Pregame Props to #{current_preference} 👋"
      quick_reply(text, menu)
    end

    if message.text == 'In Game Props'
      @user.in_game_props ? current_preference = "ON" : current_preference = "OFF"
      @user.in_game_props ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "IN_GAME_PROPS_#{preference}"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "We wanted to give you a little more action each week, so we added the option to challenge your friends during the games.\n\nWe currently have your notifications set to #{current_preference}.\n\nTap below to update your preference 🙌"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'IN_GAME_PROPS_ON'
      @user.update_attribute(:in_game_props, true)
      @user.in_game_props ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your In Game Props to #{current_preference} 🤝"
      quick_reply(text, menu)
    elsif message.quick_reply == 'IN_GAME_PROPS_OFF'
      @user.update_attribute(:in_game_props, false)
      @user.in_game_props ? current_preference = "ON" : current_preference = "OFF"
      menu = [
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      text = "We've set your In Game Props to #{current_preference} 👋"
      quick_reply(text, menu)
    end

    if message.text == 'Game Recaps'
      menu = [
        {
          content_type: 'text',
          title: "Every Win",
          payload: "RECAP_EVERY_WIN"
        },
        {
          content_type: 'text',
          title: "Every Loss",
          payload: "RECAP_EVERY_LOSS"
        },
        {
          content_type: 'text',
          title: 'Two Wins',
          payload: 'RECAP_TWO_WINS'
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
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
      text = "Tell us when you would like to be notified about your results 🤔"
      quick_reply(text, menu)
    end

    if message.quick_reply == 'RECAP_EVERY_WIN'
      @user.update_attribute(:postgame_recap_all, !@user.postgame_recap_all)
      @user.postgame_recap_all ? text = "You will get a notification every time you win or lose.\n\nTap below to update your preference 👇" : text = "You will not get a notification every time you win or lose.\n\nTap below to update your preference 👇"
      @user.postgame_recap_all ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_EVERY_WIN"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_EVERY_LOSS'
      @user.update_attribute(:postgame_recap_loss, !@user.postgame_recap_loss)
      @user.postgame_recap_loss ? text = "You will get a notification every time lose.\n\nTap below to update your preference 👇" : text = "You will not get a notification every time you lose.\n\nTap below to update your preference 👇"
      @user.postgame_recap_loss ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_EVERY_LOSS"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_TWO_WIN'
      @user.update_attribute(:postgame_recap_two, !@user.postgame_recap_two)
      @user.postgame_recap_two ? text = "You will get a notification whenever you hit 2 wins in a row.\n\nTap below to update your preference 👇" : text = "You will not get a notification whenever you hit 2 wins in a row.\n\nTap below to update your preference 👇"
      @user.postgame_recap_two ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_TWO_WINS"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_THREE_WIN'
      @user.update_attribute(:postgame_recap_three, !@user.postgame_recap_three)
      @user.postgame_recap_three ? text = "You will get a notification whenever you hit 3 wins in a row.\n\nTap below to update your preference 👇" : text = "You will not get a notification whenever you hit 3 wins in a row.\n\nTap below to update your preference 👇"
      @user.postgame_recap_three ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_THREE_WINS"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

      quick_reply(text, menu)
    elsif message.quick_reply == 'RECAP_SWEEP'
      @user.update_attribute(:postgame_recap_sweep, !@user.postgame_recap_sweep)
      @user.postgame_recap_sweep ? text = "You will get a notification whenever you hit a Sweep.\n\nTap below to update your preference 👇" : text = "You will not get a notification whenever you hit a Sweep.\n\nTap below to update your preference 👇"
      @user.postgame_recap_sweep ? preference = "OFF" : preference = "ON"
      menu = [
        {
          content_type: 'text',
          title: preference,
          payload: "RECAP_SWEEP"
        },
        {
          content_type: 'text',
          title: 'Preferences',
          payload: 'PREFERENCES'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]

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
      text = "Want to get back to seeing your selected picks, update picks, or see your current status? Tap below 👌"
      quick_reply(text, MAIN_MENU)
    end


    if message.text == 'My Picks'
      text = "You’ve got #{@user.current_picks.count} games coming up!  Tap on any of the teams below for more fun facts and details 👇"
      quick_reply(text, @menu)
    end

    if message.quick_reply == "MATCHUP_#{matchup_id}_PAYLOAD"
      pick = @user.current_picks.find_by_matchup_id(matchup_id)
      text = pick.matchup.matchup_detail.details(pick)
      quick_reply(text, @menu)
    end

    if message.text == 'Select Picks'
      pick_card = [
        {
          title: 'Select Picks Now',
          image_url: 'https://i.imgur.com/zj346Gb.png',
          buttons: [
            {
              type: 'web_url',
              messenger_extensions: true,
              title: 'Pick Now',
              url: "https://18c9b5a6.ngrok.io?id=#{@user.id}",
              webview_height_ratio: 'tall'
            }
          ]
        }
      ]
      menu = [{content_type: 'text',title: 'My Picks',payload: 'SEE_PICKS'}, {content_type: 'text',title: 'Current Status',payload: 'STATUS'}]
      say(pick_card, menu)
    end

    if message.text == 'Current Status'
      if @user.current_picks.length == 0
        quick_reply("You don't have any picks yet! Get started below 👇", MAIN_MENU)
      else
        status_card = [
          {
            content_type: "text",
            title: "🎢 History",
            payload: "HISTORY"
          },
          {
            content_type: 'text',
            title: '👥 Friends Picks',
            payload: 'FRIENDS_PICKS'
          },
          {
            content_type: 'text',
            title: 'Main Menu',
            payload: 'MAIN_MENU'
          }
        ]
        @user.current_streak >= 1 ? emoji = "😃" : emoji = "😕"
        game_time = DateTime.new(
          @user.current_picks.first.matchup.start_time_year, 
          @user.current_picks.first.matchup.start_time_month, 
          @user.current_picks.first.matchup.start_time_day, 
          @user.current_picks.first.matchup.start_time_hour, 
          @user.current_picks.first.matchup.start_time_minute, 
          00
        )
        # time_until = ((game_time - DateTime.now) * 24 * 60).to_i

        if @user.current_picks.first.matchup.started? && @user.current_picks.length >= 2
          text = "You're currently at #{@user.current_streak} wins #{emoji}\n\nYou've got the #{@user.current_picks.first.team.name.split(' ')[-1]} (#{@user.current_picks.first.spread}) going at it now.\n\nYour next pick up is the #{@user.current_picks.second.team.name.split(' ')[-1]} (#{@user.current_picks.second.spread})."
        elsif @user.current_picks.first.matchup.started? && @user.current_picks.length < 2
          text = "You're currently at #{@user.current_streak} wins #{emoji}\n\nYou've got the #{@user.current_picks.first.team.name.split(' ')[-1]} (#{@user.current_picks.first.spread}) going at it now.\n\nYou don't have anything up next, but theres still some matchups that havent started yet!"
        else
          text = "You're currently at #{@user.current_streak} wins #{emoji}\n\nYou've got action on the #{@user.current_picks.first.team.name.split(' ')[-1]} (#{@user.current_picks.first.spread}) coming up next. They're up against the #{@user.current_picks.first.opponent.name.split(' ')[-1]}"
        end        
        quick_reply(text, status_card)
      end                           
    end

    if message.text == '🎢 History'
      status_card = [
        {
          content_type: 'text',
          title: 'Current Status',
          payload: 'STATUS'
        },
        {
          content_type: 'text',
          title: '👥 Friends Picks',
          payload: 'FRIENDS_PICKS'
        },
        {
          content_type: 'text',
          title: 'Main Menu',
          payload: 'MAIN_MENU'
        }
      ]
     if @user.completed_picks.length > 0
        text = "Here's what you've got so far...\n\nSweep Count: #{@user.sweep_count}\n\nOverall Record: #{@user.picks.wins.count}-#{@user.picks.losses.count}"
        quick_reply(text, status_card)
      else
        text = "Welp, it doesn't look like we have a history yet 🤷\n\nFeel free to check back here once you've played a bit more.\n\nWe promise we'll have some fun stats for ya 😉"
        quick_reply(text, status_card)
      end
    end

    if message.text == '👥 Friends Picks'
      status_card = [
        {
          content_type: 'text',
          title: 'Current Status',
          payload: 'STATUS'
        },
        {
          content_type: "text",
          title: "🎢 History",
          payload: "HISTORY"
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
      say(options, status_card)

      # text = "It looks like you don’t have any friends playing on Sweep yet.\n\nYou can always invite them using the option in our menu below 👇\n\nYou’ll be able to see their picks and compare your records for the ultimate bragging rights! 😎"
      # quick_reply(text, status_card)
    end

  end

end

start