class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])

    # End interview if expired
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip.downcase

    # Detect "end" command BEFORE saving message
    if user_input.start_with?("end")
      @session.update!(status: "completed")

      respond_to do |format|
        format.html { redirect_to final_report_assistant_session_path(@session) }

        # Turbo Stream redirect to report
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

    # Save user message
    @message = @session.messages.create!(
      role: "user",
      content: raw_input
    )

    # Last question reached
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # Generate next question
    next_q = @session.current_question_number + 1

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    history = @session.messages.order(:created_at).last(10)
               .map { |m| "#{m.role.capitalize}: #{m.content}" }.join("\n")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_q}.
    PROMPT

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_q)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end
end
