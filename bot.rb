require 'facebook/messenger'

include Facebook::Messenger

# Subcribe bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

IDIOMS = {
  not_found: 'There were no results. Ask me again, please',
  set_bankroll: 'Select a starting bankroll',
  set_risk: 'How aggressive would you like to be?',
  unknown_command: 'Sorry, I did not recognize your command',
  menu_greeting: 'What would you like to get started with first?',
  continue: 'Continue'
}

ADDITIONAL_REPLIES = [
  {
    content_type: 'text',
    title: 'Make Picks',
    payload: 'MAKE_PICKS'
  },
  {
    content_type: 'text',
    title: 'Show Picks',
    payload: 'SHOW_PICKS'
  },
  {
    content_type: 'text',
    title: 'Give Picks',
    payload: 'GIVE_PICKS'
  }
]

MAIN_MENU = [
  {
    content_type: 'text',
    title: 'Set My Bankroll',
    payload: 'BANKROLL'
  },
  {
    content_type: 'text',
    title: 'Give Me Your Picks',
    payload: 'PICKS'
  },
]

BANKROLL_AMOUNT = [
  {
    content_type: 'text',
    title: '500',
    payload: 'LOW_AMOUNT'
  },
  {
    content_type: 'text',
    title: '1000',
    payload: 'MEDIUM_AMOUNT'
  },
  {
    content_type: 'text',
    title: '1500',
    payload: 'HIGH_AMOUNT'
  }
]

RISK_REPLIES = [
  {
    content_type: 'text',
    title: 'Low Risk',
    payload: 'LOW_RISK'
  },
  {
    content_type: 'text',
    title: 'Medium Risk',
    payload: 'MEDIUM_RISK'
  },
  {
    content_type: 'text',
    title: 'High Risk',
    payload: 'HIGH_RISK'
  }
]

def say(recipient_id, greeting, quick_replies = nil)
  if greeting == 'picks'
    message_options = {
      recipient: { id: recipient_id },
      message: { 
        attachment: {
          type: 'template',
          payload: {
            template_type: 'list',
            top_element_style: 'compact',
            elements: system_picks[0..3],
            buttons: [
              { title: "View More", type: 'postback', payload: 'view_more' }
            ]
          }
        }
      }
    }
  elsif greeting == 'picks_2'
    message_options = {
      recipient: { id: recipient_id },
      message: { 
        attachment: {
          type: 'template',
          payload: {
            template_type: 'list',
            top_element_style: 'compact',
            elements: system_picks[4..7],
            buttons: [
              { title: "View More", type: 'postback', payload: 'view_more' }
            ]
          }
        }
      }
    }
  else
    message_options = {
      recipient: { id: recipient_id },
      message: { text: greeting }
    }
  end

  message_options[:message][:quick_replies] = quick_replies if quick_replies

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
end

def system_picks
  [
    { title: "Jacksonville Jaguars at +1", subtitle: "Love the Jags as a home dog.", image_url: "http://cdn.wallpapersafari.com/51/36/zMTk0I.jpg" },
    { title: "New Orleans Saints at +6", subtitle: "Contrarian pick here, take the home team off a bad week.", image_url: "http://1000logos.net/wp-content/uploads/2017/04/Color-New-Orleans-Saints-Logo.jpg" },
    { title: "Indianapolis Colts at +7", subtitle: "I know the Colts suck, but its too good to be true.", image_url: "http://content.sportslogos.net/logos/7/158/full/593.png" },
    { title: "Pittsburgh Steelers at -6", subtitle: "This is the perfect buy low opp, fade the public.", image_url: "http://prod.static.steelers.clubs.nfl.com/nfl-assets/img/gbl-ico-team/PIT/logos/home/large.png" },   
    { title: "New York Jets at +13", subtitle: "Love the Jags as a home dog.", image_url: "https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/New_York_Jets_logo.svg/1280px-New_York_Jets_logo.svg.png" },
    { title: "Denver Broncos at +2.5", subtitle: "Contrarian pick here, take the home team off a bad week.", image_url: "https://www.deluxe.com/blog/wp-content/uploads/2014/01/Denver_Broncos_Logo.jpg" },
    { title: "San Francisco 49ers at +14", subtitle: "I know the Colts suck, but its too good to be true.", image_url: "http://prod.static.49ers.clubs.nfl.com/nfl-assets/img/gbl-ico-team/SF/logos/home/large.png" },
    { title: "Atlanta Falcons at -3", subtitle: "This is the perfect buy low opp, fade the public.", image_url: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c5/Atlanta_Falcons_logo.svg/1080px-Atlanta_Falcons_logo.svg.png" },
    { title: "New York Giants at -3", subtitle: "This is the perfect buy low opp, fade the public.", image_url: "http://content.sportslogos.net/logos/7/166/full/919.gif" }  
  ]
end

def reply_set_bankroll(message)
  sender_id = message.sender['id']
  show_menu(sender_id, IDIOMS[:set_bankroll], BANKROLL_AMOUNT)
end

def reply_set_risk(message)
  sender_id = message.sender['id']
  show_menu(sender_id, IDIOMS[:set_risk], RISK_REPLIES)
end

def show_menu(id, greeting, quick_replies = nil)
  say(id, greeting, quick_replies)
  wait_for_user
end

def to_wager(num)
  sprintf('%.2f', num)
end

def start
  Bot.on :message do |message|
    message.typing_on
    show_menu(message.sender['id'], IDIOMS[:menu_greeting], MAIN_MENU)
  end
end

def wait_for_user
  Bot.on :postback do |postback|
    if postback.payload == 'view_more'
      show_menu(postback.sender['id'], 'picks_2', ADDITIONAL_REPLIES)
    end
  end
  Bot.on :message do |message|
    if message.text == 'Set My Bankroll'
      message.typing_on
      message.reply(text: "Great, lets get started!")
      message.typing_on
      reply_set_bankroll(message)
    end

    if message.text == '500' || message.text == '1000' || message.text == '1500'
      @bankroll = {user_id: message.sender['id'], amount: message.text}
      message.typing_on
      reply_set_risk(message)
    end

    if message.text == 'Low Risk'
      @bankroll.merge!({risk: 0.01})
      unit = @bankroll[:amount].to_f * @bankroll[:risk]
      message.typing_on
      message.reply(text: "Great, we will use $#{to_wager(unit)} for each pick you make or choose to follow.")
      message.typing_on
      show_menu(message.sender['id'], IDIOMS[:continue], ADDITIONAL_REPLIES)
    elsif message.text == 'Medium Risk'
      @bankroll.merge!({risk: 0.02})
      unit = @bankroll[:amount].to_f * @bankroll[:risk]
      message.typing_on
      message.reply(text: "Great, we will use $#{to_wager(unit)} for each pick you make or choose to follow.")
      message.typing_on
      show_menu(message.sender['id'], IDIOMS[:continue], ADDITIONAL_REPLIES)
    elsif message.text == 'High Risk'
      @bankroll.merge!({risk: 0.03})
      unit = @bankroll[:amount].to_f * @bankroll[:risk]
      message.typing_on
      message.reply(text: "Great, we will use $#{to_wager(unit)} for each pick you make or choose to follow.")
      message.typing_on
      show_menu(message.sender['id'], IDIOMS[:continue], ADDITIONAL_REPLIES)
    end

    if message.text == 'Give Me Your Picks'
      message.typing_on
      show_menu(message.sender['id'], 'picks', ADDITIONAL_REPLIES)
    end
    
  end
end

start