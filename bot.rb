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
    payload: 'MAKE_PICKS'
  },
  {
    content_type: 'text',
    title: 'See Picks 👀',
    payload: 'SEE_PICKS'
  },
  {
    content_type: 'text',
    title: 'Current Streak 📈',
    payload: 'CURRENT_STREAK'
  },
]

def say(recipient_id, quick_replies, message)  
  message_options = {
    recipient: { id: recipient_id },
    message: { 
      text: message
    }
  }

  message_options[:message][:quick_replies] = quick_replies if quick_replies

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])

  wait_for_user
end

def start

  # Bot.on :optin do |optin|
  #   optin.reply(text: 'Ah, human!')
  #   puts optin.inspect
  # end

  # Bot.on :delivery do |deliver|
  #   puts "Deliver..."
  #   puts deliver.inspect
  # end

  # Bot.on :read do |read|
  #   puts "Read..."
  #   puts read.inspect
  # end

  message = 'A simple, quick, and fun way to win Amazon Gift Cards while you watch the NFL every week.'
  say('1328837993906209', MAIN_MENU, message)
end

def wait_for_user
  Bot.on :postback do |postback|
    if postback.payload == 'MAIN_MENU_PAYLOAD'
      sleep 1
      message = "Select from the options below to get started or check on any updates"
      say('1328837993906209', MAIN_MENU, message)
    end
  end

  Bot.on :message do |message|
    if message.text == 'Make Picks 🎉'
      # message.typing_on
      sleep 1
      message.reply(
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: "Awesome, lets get started!",
            buttons: [
              {
                type: 'web_url',
                messenger_extensions: true,
                title: 'Make Picks 🏈',
                url: 'https://4e5b0417.ngrok.io',
                webview_height_ratio: 'full'
              },
              {
                type: 'postback',
                title: 'Main Menu 🏠',
                payload: 'MAIN_MENU_PAYLOAD'
              }
            ]
          }
        }
      )
    end

    if message.text == 'See Picks 👀'
      # message.typing_on
      sleep 1
      message.reply(
        "attachment":{
              "type":"template",
              "payload":{
                "template_type":"generic",
                "elements":[
                   {
                    "title":"Cardinals",
                    "image_url":"https://petersfancybrownhats.com/company_image.png",
                    "subtitle":"We\'ve got the right hat for everyone.",
                    "default_action": {
                      "type": "web_url",
                      "url": "https://github.com/",
                      "messenger_extensions": true,
                      "webview_height_ratio": "tall",
                      "fallback_url": ""
                    },
                    "buttons":[
                      {
                        "type":"web_url",
                        "url":"https://github.com/",
                        "title":"More Details"
                      },{
                        "type":"postback",
                        "title":"Change Pick",
                        "payload":"DEVELOPER_DEFINED_PAYLOAD"
                      }              
                    ]      
                  },
                   {
                    "title":"Falcons",
                    "image_url":"https://petersfancybrownhats.com/company_image.png",
                    "subtitle":"We\'ve got the right hat for everyone.",
                    "default_action": {
                      "type": "web_url",
                      "url": "https://github.com/",
                      "messenger_extensions": true,
                      "webview_height_ratio": "tall",
                      "fallback_url": ""
                    },
                    "buttons":[
                      {
                        "type":"web_url",
                        "url":"https://github.com/",
                        "title":"More Details"
                      },{
                        "type":"postback",
                        "title":"Change Pick",
                        "payload":"DEVELOPER_DEFINED_PAYLOAD"
                      }              
                    ]      
                  }
                ]
              }
            }
      )
    end

    if message.text == 'Current Streak 📈'
      sleep 1
      message.reply(
              "attachment":{
                "type":"template",
                "payload":{
                  "template_type":"generic",
                  "elements":[
                     {
                      "title":"Current streak of 2!",
                      "image_url":"https://petersfancybrownhats.com/company_image.png",
                      "subtitle":"We\'ve got the right hat for everyone.",
                      "buttons":[
                        {
                          "type":"postback",
                          "title":"Check Your Friends Streak",
                          "payload":"DEVELOPER_DEFINED_PAYLOAD"
                        },
                        {
                          "type":"postback",
                          "title":"Change Pick",
                          "payload":"DEVELOPER_DEFINED_PAYLOAD"
                        }              
                      ]      
                    }
                  ]
                }
              }
            )
    end

  end
end

start