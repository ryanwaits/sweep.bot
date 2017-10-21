require 'facebook/messenger'
require './lib/text_message'
require './lib/attachment_message'

include Facebook::Messenger

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

IDIOMS = {
  not_found: 'There were no results. Ask me again, please',
  unknown_command: 'Sorry, I did not recognize your command',
  menu_greeting: 'What would you like to get started with first',
  continue: 'Continue',
  confirm: 'Does that sound right?'
}

MAIN_MENU = [
  {
    content_type: 'text',
    title: 'Get Started',
    payload: 'GAMES'
  }
]

@games ||= 1
@selected_games ||= []

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

def show_carousel(recipient_id)
  @text = TextMessage.new(recipient_id, "You selected #{@selected_games[0..(-1 -1)].join(', ') + ' and ' + @selected_games[-1]}.")
  Bot.deliver(@text.format, access_token: ENV['ACCESS_TOKEN'])
  show_menu(recipient_id, IDIOMS[:menu_greeting], MAIN_MENU)
  wait_for_user
end

def show_games(recipient_id)
  if @games == 1
    @game = {
            "title":"Los Angeles Rams vs. Arizona Cardinals",
            "image_url":"http://www.arizonacardinalsvslosangelesrams.us/wp-content/uploads/2017/04/Arizona-Cardinals-vs-Los-Angeles-Rams-300x169.jpg",
            "buttons":[
              {
                "type":"postback",
                "title":"Rams -3",
                "payload":"NEXT"
              },{
                "type":"postback",
                "title":"Cardinals +3",
                "payload":"NEXT"
              }              
            ]      
          }
        elsif @games == 2
          @game = {
            "title":"Dallas Cowboys vs. San Francisco 49ers",
            "image_url":"http://www.exclusiveworldpremiere.tv/wp-content/uploads/2016/10/Dallas-Cowboys-Vs-San-Francisco-49ers-NFL-Poster.jpg",
            "buttons":[
              {
                "type":"postback",
                "title":"Cowboys -6",
                "payload":"NEXT"
              },{
                "type":"postback",
                "title":"49ers +6",
                "payload":"NEXT"
              }              
            ]      
          }
        elsif @games == 3
          @game = {
            "title":"Atlanta Falcons vs. New England Patriots",
            "image_url":"https://pmchollywoodlife.files.wordpress.com/2017/02/falcons-vs-patriots-super-bowl-commercials-ftr.jpg",
            "buttons":[
              {
                "type":"postback",
                "title":"Falcons +4.5",
                "payload":"NEXT"
              },{
                "type":"postback",
                "title":"Patriots -4.5",
                "payload":"NEXT"
              }              
            ]      
          }
        elsif @games == 4
          @game = {
            "title":"Washington Redskins vs. Philadelphia Eagles",
            "image_url":"http://www.jakessteaks.net/js/wp-content/uploads/redskins-vs-eagles.jpg",
            "buttons":[
              {
                "type":"postback",
                "title":"Redskins +5",
                "payload":"LAST"
              },{
                "type":"postback",
                "title":"Eagles -5",
                "payload":"LAST"
              }              
            ]      
          }
  end
  @attachment = AttachmentMessage.new(recipient_id, [@game])
  Bot.deliver(@attachment.list_format, access_token: ENV['ACCESS_TOKEN'])
  @games += 1
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
      @selected_games.push(postback.messaging['postback']['title'])
      show_games(postback.sender['id'])
    end
    if postback.payload == 'LAST'
      @selected_games.push(postback.messaging['postback']['title'])
      show_carousel(postback.sender['id'])
    end
  end

  Bot.on :message do |message|
    if message.text == 'Get Started'
      message.typing_on
      show_games(message.sender['id'])
    end    
  end
end

start