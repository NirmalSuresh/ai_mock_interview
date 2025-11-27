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

    # --- MANUAL “end” COMMAND ---
    if user_input.downcase.start_with?("end")
      @session.update!(status: "completed")

      respond_to do |format|
        format.html { redirect_to final_report_assistant_session_path(@session) }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "messages",
            partial: "assistant_sessions/redirect_to_report",
            locals: { session: @session }
          )
        end
      end
      return
    end

    # --- SAVE USER MESSAGE ---
    @message = @session.messages.create!(
      role: "user",
      content: raw_input.presence,
      attachment: message_params[:attachment]
    )

    # =========================================================
    #              FILE ATTACHED (PDF/IMAGE/AUDIO)
    # =========================================================
    if @message.attachment.attached?
      # Convert Cloudinary blob → local tmp file → RubyLLM "with" hash
      with_payload = FileAnalyzer.call(@message.attachment.blob)

      ruby_llm = RubyLLM.chat(model: "gpt-4o-mini")

      prompt = "Analyze the uploaded file and give short, clear interview-related feedback."

      response = ruby_llm.ask(prompt, with: with_payload)

      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: response&.content || "I couldn't analyze that file."
      )

      return respond_ok
    end

    # =========================================================
    #                NORMAL INTERVIEW QUESTION FLOW
    # =========================================================
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10).map do |m|
      "#{m.role.capitalize}: #{m.content}"
    end.join("\n")

    ruby_llm = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = ruby_llm.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_q}.
    PROMPT

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content.presence || "Please repeat your answer."
    )

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
