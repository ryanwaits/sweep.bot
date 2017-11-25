require 'facebook/messenger'
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
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])


# MAIN_MENU = [
#   {
#     content_type: 'text',
#     title: 'Make Picks 🎉',
#     payload: 'MAKE_PICKS'
#   },
#   {
#     content_type: 'text',
#     title: 'See Picks 👀',
#     payload: 'SEE_PICKS'
#   },
#   {
#     content_type: 'text',
#     title: 'Current Streak 📈',
#     payload: 'CURRENT_STREAK'
#   }
# ]

STARTER_MENU = [
  {
    title: "See Picks 👀",
    image_url: "https://png.icons8.com/?id=13119&size=500",
    subtitle: "Ego is about who's right. Truth is about what's right.",
    default_action: {
      type: "web_url",
      url: "https://github.com/",
      messenger_extensions: true,
      webview_height_ratio: "tall",
      fallback_url: ""
    },
    buttons: [
      {
        type: 'postback',
        title: 'See Picks 👀',
        payload: 'SEE_PICKS'
      }
    ]   
  },
   {
    title: "Make Picks 🎉",
    image_url: "https://png.icons8.com/?id=13037&size=500",
    subtitle: "Ego is about who's right. Truth is about what's right.",
    default_action: {
      type: "web_url",
      url: "https://0738e13a.ngrok.io",
      messenger_extensions: true,
      webview_height_ratio: "tall"
    },
    buttons: [
      {
        type: 'web_url',
        messenger_extensions: true,
        title: 'Make Picks 🏈',
        url: 'https://0738e13a.ngrok.io',
        webview_height_ratio: 'tall'
      }
    ]   
  },
  {
    title: "Status Check 📈",
    image_url: "https://png.icons8.com/?id=42890&size=500",
    subtitle: "Ego is about who's right. Truth is about what's right.",
    default_action: {
      type: "web_url",
      url: "https://github.com/",
      messenger_extensions: true,
      webview_height_ratio: "tall"
    },
    buttons: [
      {
        type: 'postback',
        title: 'Status Check 📈',
        payload: 'STATUS_CHECK'
      }
    ]  
  }
]

def say(recipient_id, options)  
  message_options = {
    recipient: { id: recipient_id },
    message: { 
      attachment: {
        type: 'template',
        payload: {
          template_type: 'generic',
          elements: options
        }
      }
    }
  }

  # message_options[:message][:quick_replies] = quick_replies if quick_replies

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])

  wait_for_user
end

def start
  @recipient_id = '1328837993906209'

  # Bot.on :referral do |referral|
  #   referral.sender    # => { 'id' => '1008372609250235' }
  #   referral.recipient # => { 'id' => '2015573629214912' }
  #   referral.sent_at   # => 2016-04-22 21:30:36 +0200
  #   referral.ref       # => 'MYPARAM'
  # end

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

  say(@recipient_id, STARTER_MENU)
end

def set_matchup_payloads(current_picks)
  api = SweepApi.new
  payloads = current_picks.each do |current_pick|
    api.set_matchup_details(current_pick['matchup_id'])
  end
  payloads
end

def wait_for_user

  Bot.on :postback do |postback|
    puts "sender id => #{postback.sender}"
    puts "recipient id => #{postback.recipient}"
    puts "sent at => #{postback.sent_at}"
    puts "payload => #{postback.payload}"
    @payloads = []

    if postback.payload == 'SEE_PICKS'
      current_picks = SweepApi.new.get_current_picks
      picks_menu = []
      current_picks.each do |current_pick|
        picks_menu.push(
          {
            title: current_pick['team'],
            image_url: current_pick['team_url'],
            buttons: [
              {
                type: 'postback',
                title: 'More Details',
                payload: "MATCHUP_#{current_pick['matchup_id']}_PAYLOAD"
              },
              {
                type: 'postback',
                title: 'Back',
                payload: "BACK_PAYLOAD"
              }
            ]
          }
        )
      end
      say(@recipient_id, picks_menu)
    end

    if postback.payload == 'STATUS_CHECK'
      status = SweepApi.new.get_status
      message_options = {
        recipient: { id: @recipient_id },
        message: { 
          text: "You have a current streak of #{status[:current_streak]}"
        }
      }

      Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
      wait_for_user
    end

  end
end

start