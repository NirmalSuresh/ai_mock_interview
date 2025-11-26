class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip

    return redirect_to assistant_session_path(@session) if user_input.blank?

    if end_command?(user_input)
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.create!(
      role: "user",
      content: user_input
    )

    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at)
                 .last(10)
                 .map { |m| "#{m.role.capitalize}: #{m.content}" }
                 .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Conversation so far:
      #{history}

      Ask interview question number #{next_q}.
    PROMPT

    @assistant_message = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_q)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  private

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
  end

  def end_command?(content)
    normalized = content.to_s.downcase.strip
    normalized == "end" || normalized.start_with?("end ")
  end
end
