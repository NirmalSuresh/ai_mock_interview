class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = AssistantSession.find(params[:assistant_session_id])

    # Save user message
    @session.messages.create!(
      role: "user",
      content: params[:content]
    )

    # Prepare conversation history
    history = @session.messages.map do |msg|
      { role: msg.role, content: msg.content }
    end

    # Call AI (RubyLLM)
    ai = RubyLLM::Chat.completions(
      model: "gpt-4o-mini",
      messages: history
    )

    ai_reply = ai.output  # <-- IMPORTANT: this is the actual string

    # Save assistant reply
    @session.messages.create!(
      role: "assistant",
      content: ai_reply
    )

    redirect_to assistant_session_path(@session)
  end
end
