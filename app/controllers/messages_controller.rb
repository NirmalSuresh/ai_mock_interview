class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw = params.dig(:message, :content).to_s.strip

    # END command
    if raw.downcase.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # Save user message
    @message = @session.messages.create!(
      role: "user",
      content: raw.presence,
      attachment: message_params[:attachment]
    )

    # File uploaded → analyze + continue
    if @message.attachment.attached?
      ai_text = FileAnalyzer.call(@message)

      @session.messages.create!(
        role: "assistant",
        content: ai_text
      )

      ask_next_question
      return respond_ok
    end

    # Normal text → next Q
    ask_next_question
    respond_ok
  end

  private

  def ask_next_question
    return finish_session if @session.current_question_number >= 25

    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10).map do |m|
      "#{m.role.capitalize}: #{m.content}"
    end.join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai = chat.ask(<<~MSG)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Conversation History:
      #{history}

      Ask interview question number #{next_q}.
    MSG

    @session.messages.create!(
      role: "assistant",
      content: ai.content.presence || "Please repeat your answer."
    )

    @session.update!(current_question_number: next_q)
  end

  def finish_session
    @session.update!(status: "completed")
    redirect_to final_report_assistant_session_path(@session)
  end

  def respond_ok
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
  end

  def message_params
    params.require(:message).permit(:content, :attachment)
  end
end
