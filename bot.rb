require 'facebook/messenger'
require './lib/bot_user'
require './lib/text_message'
require './lib/attachment_message'
require './models/sweep_api'

include Facebook::Messenger

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Facebook::Messenger::Profile.set({
  get_started: {
    payload: 'GET_STARTED_PAYLOAD'
  }
}, access_token: ENV['ACCESS_TOKEN'])

# Facebook::Messenger::Profile.set({
#   persistent_menu: [
#     {
#       locale: 'default',
#       composer_input_disabled: false,
#       call_to_actions: [
#         {
#           title: 'My Account',
#           type: 'nested',
#           call_to_actions: [
#             {
#               title: 'What is a chatbot?',
#               type: 'postback',
#               payload: 'EXTERMINATE'
#             },
#             {
#               title: 'History',
#               type: 'postback',
#               payload: 'HISTORY_PAYLOAD'
#             },
#             {
#               title: 'Contact Info',
#               type: 'postback',
#               payload: 'CONTACT_INFO_PAYLOAD'
#             }
#           ]
#         },
#         {
#           type: 'web_url',
#           title: 'Get some help',
#           url: 'https://github.com/hyperoslo/facebook-messenger',
#           webview_height_ratio: 'full'
#         }
#       ]
#     }
#   ]
# }, access_token: ENV['ACCESS_TOKEN'])


MAIN_MENU = [
  {
    content_type: 'text',
    title: '👀 My Picks',
    payload: 'SEE_PICKS'
  },
  {
    content_type: 'text',
    title: '🎉 Make Picks',
    payload: 'MAKE_PICKS'
  },
  {
    content_type: 'text',
    title: '📈 Status',
    payload: 'STATUS'
  }
]

def say(recipient_id, options, menu=nil)  
  message_options = {
    recipient: { id: recipient_id },
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

def quick_reply(recipient_id, menu)
  message_options = {
    recipient: { id: recipient_id },
    message: {
      text: "Welcome to Sweep 🔥\nLet's get started...", 
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

def wait_for_user

  Bot.on :postback do |postback|
    @recipient_id = postback.sender['id']
    puts "sender id => #{postback.sender}"
    puts "recipient id => #{postback.recipient}"
    puts "sent at => #{postback.sent_at}"
    puts "payload => #{postback.payload}"

    if postback.payload == 'GET_STARTED_PAYLOAD'
      @recipient_id = postback.sender['id']
      quick_reply(@recipient_id, MAIN_MENU)
    end

    if postback.payload == 'MATCHUP_1_PAYLOAD'
      message_options = {
        recipient: { id: @recipient_id },
        message: { 
          text: "Details about the game..."
        }
      }

      quick_reply(@recipient_id, MAIN_MENU)
    end

  end

  Bot.on :message do |message|
    message.typing_off
    @recipient_id = message.sender['id']
    if message.text == '👀 My Picks'

      current_picks = SweepApi.new.get_current_picks
      picks_menu = []

      current_picks.each do |current_pick|
        picks_menu.push(
          {
            title: 'Buffalo Bills', 
            image_url: 'http://oi68.tinypic.com/bi835x.jpg',
            buttons: [
              {
                type: 'postback',
                title: 'More Details',
                payload: "MATCHUP_#{current_pick['matchup_id']}_PAYLOAD"
              }
            ]
          }
        )
      end

      say(@recipient_id, picks_menu, MAIN_MENU)
    end

    if message.text == '🎉 Make Picks'
      pick_card = [
        {
          title: 'Make your picks now!',
          image_url: 'https://png.icons8.com/?id=13037&size=500',
          buttons: [
            {
              type: 'web_url',
              messenger_extensions: true,
              title: 'Lets do it',
              url: 'https://0738e13a.ngrok.io',
              webview_height_ratio: 'tall'
            }
          ]
        }
      ]
      say(@recipient_id, pick_card, MAIN_MENU)
    end

    if message.text == '📈 Status'
      current_streak_message = text_reply(@recipient_id, "You have a current streak of 1", MAIN_MENU)
      Bot.deliver(current_streak_message, access_token: ENV['ACCESS_TOKEN'])   
      wait_for_user
    end
  end

  Bot.on :referral do |referral|
    referral.sender    # => { 'id' => '1008372609250235' }
    referral.recipient # => { 'id' => '2015573629214912' }
    referral.sent_at   # => 2016-04-22 21:30:36 +0200
    referral.ref       # => 'MYPARAM'
  end

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

end

start