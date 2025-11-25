class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = AssistantSession.find(params[:assistant_session_id])

    # Save the user's message
    user_msg = @session.messages.create!(
      role: "user",
      content: params[:content]
    )

    # Call OpenAI
    ai_response = OpenAIClient.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_messages(@session)
      }
    )

    bot_text = ai_response["choices"][0]["message"]["content"]

    # Save AI response
    @session.messages.create!(
      role: "assistant",
      content: bot_text
    )

    redirect_to assistant_session_path(@session)
  end

  private

  # Convert previous messages to OpenAI format
  def build_messages(session)
    session.messages.order(:created_at).map do |m|
      { role: m.role, content: m.content }
    end
  end
end
