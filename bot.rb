require 'facebook/messenger'
require './lib/text_message'
require './lib/attachment_message'

include Facebook::Messenger

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

IDIOMS = {
  not_found: 'There were no results. Ask me again, please',
  unknown_command: 'Sorry, I did not recognize your command',
  menu_greeting: 'What would you like to get started with first',
  continue: 'Continue'
}

MAIN_MENU = [
  {
    content_type: 'text',
    title: 'Get Picks',
    payload: 'PICKS'
  }
]

def get_or_create_user(uuid)
  @user = User.find_by_facebook_uuid(uuid) || nil
  @user = User.create(facebook_uuid: uuid, username: "testuser") unless @user
end

def say(recipient_id, greeting, quick_replies)
  get_or_create_user(recipient_id)

  if @user
    message_options = {
      recipient: { id: recipient_id },
      message: { text: "#{greeting} #{@user.username}?" }
    }
  else
  message_options = {
    recipient: { id: recipient_id },
    message: { text: "#{greeting}?" }
  }
  end

  message_options[:message][:quick_replies] = quick_replies if quick_replies

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
end

def show_games(recipient_id)
  @attachment = AttachmentMessage.new(recipient_id, ["Redskins +7", "Chiefs -7"])
  Bot.deliver(@attachment.button_format, access_token: ENV['ACCESS_TOKEN'])
  wait_for_user
end

def show_menu(id, greeting, quick_replies = nil)
  say(id, greeting, quick_replies)
  wait_for_user
end

def start
  Bot.on :message do |message|
    message.typing_on
    show_menu(message.sender['id'], IDIOMS[:menu_greeting], MAIN_MENU)
  end
end

def wait_for_user
  Bot.on :postback do |postback|
    if postback.payload == 'NEXT'
      show_games(message.sender['id'])
    end
  end

  Bot.on :message do |message|
    if message.text == 'Get Picks'
      message.typing_on
      show_games(message.sender['id'])
    end    
  end
end

start