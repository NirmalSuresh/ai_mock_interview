class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])

    # Expired session → end immediately
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input  = params.dig(:message, :content).to_s
    user_input = raw_input.strip.downcase

    # -------------------------------
    # END COMMAND → redirect to report
    # -------------------------------
    if user_input.start_with?("end")
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

    # ------------------------
    # Save user message
    # ------------------------
    @session.messages.create!(
      role: "user",
      content: raw_input
    )

    # ------------------------
    # Last question → end test
    # ------------------------
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # ------------------------
    # Generate NEXT question
    # ------------------------
    next_q = @session.current_question_number + 1

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    # Keep short history for clarity
    history = @session.messages.order(:created_at).last(10).map do |m|
      "#{m.role.upcase}: #{m.content}"
    end.join("\n\n")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_q}.
    PROMPT

    @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    # Advance question number
    @session.update!(current_question_number: next_q)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end
end
