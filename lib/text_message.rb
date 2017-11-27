class TextMessage

  def initialize recipient_id, message, menu
    @recipient_id, @message, @menu = recipient_id, message, menu
  end

  def format
    {
      recipient: { id: @recipient_id },
      message: { 
        text: @message,
        quick_replies: @menu
      }
    }
  end

end