class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = AssistantSession.find(params[:assistant_session_id])

    @session.messages.create!(
      role: "user",
      content: params[:message][:content]
    )

    formatted_messages = @session.messages.map do |m|
      { role: m.role, content: m.content }
    end

    client = RubyLLM::Client.new
    response = client.chat.completions.create(
      model: "gpt-4o-mini",
      messages: formatted_messages,
      with_instructions: system_prompt
    )

    ai_reply = response["choices"][0]["message"]["content"]

    @session.messages.create!(
      role: "assistant",
      content: ai_reply
    )

    redirect_to assistant_session_path(@session)
  end

  private

  def system_prompt
    <<~PROMPT
      You are a helpful, concise AI assistant.
    PROMPT
  end
end
