class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # --- END IF SESSION EXPIRED ---
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip

    # --- DETECT "end" COMMAND ---
    if user_input.downcase.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # --- SAVE USER MESSAGE (text + optional file) ---
    @message = @session.messages.create!(
      role: "user",
      content: raw_input.presence,
      attachment: message_params[:attachment]
    )

    # --- FILE ATTACHED → ANALYZE ---
    if @message.attachment.attached?
      ai_text = FileAnalyzer.call(@message)

      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: ai_text
      )

      return respond_ok
    end

    # --- END OF INTERVIEW ---
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # --- PREVENT REPEATED QUESTIONS ---
    next_q = (@session.current_question_number || 0) + 1

    # Build SAFE history
    history = @session.messages.order(:created_at).last(10).map do |m|
      if m.attachment.present?
        "#{m.role.capitalize}: #{m.content.presence || '[User uploaded a file]'}"
      else
        "#{m.role.capitalize}: #{m.content}"
      end
    end.join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    prompt = <<~PROMPT
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Now ask interview question number #{next_q}.
    PROMPT

    ai_response = chat.ask(prompt)

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content.presence || "Please repeat your answer."
    )

    # UPDATE THE QUESTION NUMBER LAST (guarantees no duplication)
    @session.update!(current_question_number: next_q)

    respond_ok
  end

  private

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
