class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = AssistantSession.find(params[:assistant_session_id])

    user_message = @session.messages.create!(
      role: "user",
      content: params[:content]
    )

    # RubyLLM chat call
    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(params[:content])  # << IMPORTANT: .ask instead of .completions

    assistant_message = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    redirect_to assistant_session_path(@session)
  end
end
