class TextMessage

  def initialize recipient_id, content
    @recipient_id, @content, @payload = recipient_id, content
  end

  def format
    {
      recipient: { id: @recipient_id },
      message: { text: "#{@content}" }
    }
  end

end