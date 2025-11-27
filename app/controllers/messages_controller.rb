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

    # FILE UPLOADED -> ANALYZE FIRST
    if @message.attachment.attached?
      ai_text = FileAnalyzer.call(@message)

      @session.messages.create!(
        role: "assistant",
        content: ai_text
      )

      ask_next_question
      return respond_ok
    end

    # TEXT MESSAGE -> NEXT QUESTION
    ask_next_question
    respond_ok
  end

  private

  # -----------------------------------------------------
  # 🚀 MAIN QUESTION FLOW
  # -----------------------------------------------------
  def ask_next_question
    # Finish if 25 done
    return finish_session if @session.current_question_number >= 25

    next_q = @session.current_question_number + 1

    # ✅ Correct RubyLLM API for your gem version
    chat = RubyLLM::Chat.new(model: "gpt-4o-mini")

    response = chat.ask(
      "You are an interview bot. Ask question number #{next_q} " \
      "for the role: #{@session.role}. " \
      "Keep it short and only output the question."
    )

    @session.messages.create!(
      role: "assistant",
      content: response.content || "Next question #{next_q}: Please continue."
    )

    @session.update!(current_question_number: next_q)
  end

  # -----------------------------------------------------
  # 🚀 END SESSION
  # -----------------------------------------------------
  def finish_session
    @session.update!(status: "completed")
    redirect_to final_report_assistant_session_path(@session)
  end

  # -----------------------------------------------------
  # 🚀 RESPONSE HANDLING
  # -----------------------------------------------------
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
