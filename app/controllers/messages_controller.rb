class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])

    # Save user message
    user_message = @session.messages.create!(
      role: "user",
      content: params[:content]
    )

    # Call GitHub Models (RubyLLM)
    ai = RubyLLM.chat
    ai_response = ai.ask(params[:content])

    # Save AI response
    @session.messages.create!(
      role: "assistant",
      content: ai_response
    )

    redirect_to assistant_session_path(@session)
  end
end
