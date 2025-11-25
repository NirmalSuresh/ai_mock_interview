class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = AssistantSession.find(params[:assistant_session_id])

    # Save the user message first
    user_message = @session.messages.create!(
      role: "user",
      content: params[:content]
    )

    # Build full conversation for OpenAI
    conversation = @session.messages.order(:created_at).map do |m|
      { role: m.role, content: m.content }
    end

    # Add system prompt
    conversation.unshift({
      role: "system",
      content: "You are a friendly AI chat assistant."
    })

    # Call OpenAI
    client = OpenAI::Client.new
    ai_response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: conversation
    })

    # Extract AI message safely
    ai_text = ai_response.dig("choices", 0, "message", "content")

    # Save the assistant's reply
    @session.messages.create!(
      role: "assistant",
      content: ai_text
    )

    redirect_to assistant_session_path(@session)
  end
end
