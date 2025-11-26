class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # End if timer expired
    if @session.expired?
      @session.update!(status: "completed") unless @session.completed?
      return redirect_to final_report_assistant_session_path(@session),
                         alert: "Time is up. Interview finished."
    end

    raw_content = params.dig(:message, :content).to_s
    content     = raw_content.strip

    # Ignore empty answers
    if content.blank?
      return redirect_to assistant_session_path(@session)
    end

    # Save user's answer
    @message = @session.messages.create!(
      role: "user",
      content: raw_content
    )

    # If user wants to end the test manually
    if end_command?(content)
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session),
                         notice: "Interview ended by you."
    end

    # If already at question 25, finish after this answer
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session),
                         notice: "Interview completed."
    end

    # Generate next question
    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at)
                 .last(10)
                 .map { |m| "#{m.role.capitalize}: #{m.content}" }
                 .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    prompt = <<~PROMPT
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Please ask interview question number #{next_q} for this role.
    PROMPT

    ai_response = chat.ask(prompt)

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
    normalized = content.downcase
    ["end", "end test", "end the test", "finish", "stop", "quit"].include?(normalized)
  end
end
