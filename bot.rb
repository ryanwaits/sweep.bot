require 'facebook/messenger'
require './lib/text_message'
require './lib/attachment_message'

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
      composer_input_disabled: false,
      call_to_actions: [
        {
          type: 'web_url',
          title: 'Leaderboard 🏆',
          url: 'https://github.com/hyperoslo/facebook-messenger',
          webview_height_ratio: 'full'
        },
        {
          type: 'web_url',
          title: 'Invite Friends 📤',
          url: 'https://github.com/hyperoslo/facebook-messenger',
          webview_height_ratio: 'full'
        },
        {
          type: 'web_url',
          title: 'How To Play? 🤔',
          url: 'http://playsweep.com',
          webview_height_ratio: 'full'
        }
      ]
    },
    {
      locale: 'en_US',
      composer_input_disabled: false
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])

MAIN_MENU = [
  {
    content_type: 'text',
    title: 'Make Picks 🎉',
    payload: 'SELECT_GAMES'
  },
  {
    content_type: 'text',
    title: 'Current Streak 📈',
    payload: 'CURRENT_STREAK'
  },
]

def say(recipient_id, quick_replies)  
  message_options = {
    recipient: { id: recipient_id },
    message: { 
      text: "A simple, quick, and fun way to win Amazon Gift Cards while you watch the NFL every week."
    }
  }

  message_options[:message][:quick_replies] = quick_replies if quick_replies

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])

  wait_for_user
end

def start
  Bot.on :optin do |optin|
    optin.reply(text: 'Ah, human!')
    puts optin.inspect
  end

  Bot.on :delivery do |deliver|
    puts "Deliver..."
    puts deliver.inspect
  end

  Bot.on :read do |read|
    puts "Read..."
    puts read.inspect
  end

  say('1328837993906209', MAIN_MENU)
end

def wait_for_user
  Bot.on :message do |message|
    if message.text == 'Make Picks 🎉'
      message.typing_on
      sleep 1
      message.reply(
        text: "Here's the current slate for Week 9...\n"
      )
      sleep 1
      message.reply(
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: "- Bills @ Jets\n- Broncos @ Eagles\n- Chiefs @ Cowboys\n- Raiders @ Dolphins\n- Lions @ Packers",
            buttons: [
              {
                type: 'web_url',
                title: 'Get Started 🏈',
                url: 'https://github.com/hyperoslo/facebook-messenger',
                webview_height_ratio: 'full'
              },
              {
                type: 'web_url',
                title: 'More Details 🙋',
                url: 'https://github.com/hyperoslo/facebook-messenger',
                webview_height_ratio: 'full'
              }
            ]
          }
        }
      )
    end
  end
end

start