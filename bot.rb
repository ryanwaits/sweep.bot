require 'facebook/messenger'
require 'sinatra/activerecord'

require './lib/bot_user'
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
          title: '📊 Leaderboard',
          url: 'https://github.com/hyperoslo/facebook-messenger',
          webview_height_ratio: 'tall'
        },
        {
          type: 'web_url',
          title: '📫 Invite A Friend',
          url: 'https://github.com/hyperoslo/facebook-messenger',
          webview_height_ratio: 'tall'
        },
        {
          type: 'web_url',
          title: '🎮 How To Play',
          url: 'https://github.com/hyperoslo/facebook-messenger',
          webview_height_ratio: 'tall'
        }
      ]
    },
    {
      locale: 'zh_CN',
      composer_input_disabled: false
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])

MAIN_MENU = [
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
    title: '🤓 Current Status',
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
        title: "#{current_pick.team.name}",
        payload: "MATCHUP_#{current_pick.matchup_id}_PAYLOAD"
      }
    )
  end
  @menu
end

def wait_for_user

  Bot.on :postback do |postback|
    @user = User.find_or_create_by(facebook_uuid: postback.sender['id'])

    if postback.payload == 'GET_STARTED_PAYLOAD'
      text = "Welcome to Sweep 🔥\n\nLet's get started!"
      quick_reply(text, MAIN_MENU)
    end

  end

  Bot.on :message do |message|
    @user = User.find_or_create_by(facebook_uuid: message.sender['id'])
    set_matchup_details(@user.current_picks)

    if message.text == '↩️  More Options'
      message.typing_on
      text = "You have a lot of options to choose from, better get to it ⚡"
      quick_reply(text, MAIN_MENU)
    end


    if message.text == '👀 My Picks'
      message.typing_on
      @menu = @menu.push({content_type: 'text',title: '↩️  More Options',payload: 'MAIN_VIEW'})
      text = "You've got #{@user.current_picks.count} games coming up! Check out some more details below 👇"
      quick_reply(text, @menu)
    end

    if message.quick_reply == 'MATCHUP_1_PAYLOAD'
      text = @user.current_picks.find_by_matchup_id(1).matchup.matchup_detail.description
      quick_reply(text, @menu)
    end

    if message.quick_reply == 'MATCHUP_2_PAYLOAD'
      text = @user.current_picks.find_by_matchup_id(2).matchup.matchup_detail.description
      quick_reply(text, @menu)
    end

    if message.quick_reply == 'MATCHUP_3_PAYLOAD'
      text = @user.current_picks.find_by_matchup_id(3).matchup.matchup_detail.description
      quick_reply(text, @menu)
    end

    if message.quick_reply == 'MATCHUP_4_PAYLOAD'
      text = @user.current_picks.find_by_matchup_id(4).matchup.matchup_detail.description
      quick_reply(text, @menu)
    end


    if message.text == '🏆 Make Picks'
      message.typing_on
      pick_card = [
        {
          title: 'Pick your winners now 🥇',
          buttons: [
            {
              type: 'web_url',
              messenger_extensions: true,
              title: 'Select Here',
              url: "https://5a8ee13c.ngrok.io?id=#{@user.id}",
              webview_height_ratio: 'tall'
            }
          ]
        }
      ]
      menu = [{content_type: 'text',title: '👀 My Picks',payload: 'SEE_PICKS'}, {content_type: 'text',title: '🤓 Current Status',payload: 'STATUS'}]
      say(pick_card, menu)
    end

    if message.text == '🤓 Current Status'
      status_card = [
        {
          content_type: "text",
          title: "🗒 History",
          payload: "HISTORY"
        },
        {
          content_type: 'text',
          title: '👥 Friends Picks',
          payload: 'LEADERBOARD'
        },
        {
          content_type: 'text',
          title: '↩️  More Options',
          payload: 'MAIN_VIEW'
        }
      ]
      text = "Your current streak is #{@user.current_streak}.\n\nYour next matchup is the #{@user.current_picks.first.team.name} against the #{@user.current_picks.first.opponent.name}.\n\nCheck out your history below or take a look at what your friends are picking 👍"
      quick_reply(text, status_card)
    end
  end

end

start