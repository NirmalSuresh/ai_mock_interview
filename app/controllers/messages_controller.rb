class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # END IF SESSION EXPIRED
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s

    # MANUAL END
    if raw_input.strip.downcase == "end"
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # SAVE USER MESSAGE
    @message = @session.messages.create!(
      role: "user",
      content: raw_input
    )

    # GENERATE NEXT QUESTION
    generate_next_question!

    respond_ok
  end

  private

  # -------------------------------------------------
  # GENERATE NEXT QUESTION
  # -------------------------------------------------
  def generate_next_question!
    return if finish_session_if_done  # <- FIXED

    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10).map do |m|
      "#{m.role.capitalize}: #{m.content}"
    end.join("\n")

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    ai = client.chat.completions.create(
      model: "llama-3.1-70b-versatile",
      messages: [
        { role: "system", content: SystemPrompt.text },
        { role: "user", content: "Role: #{@session.role}\n\nConversation:\n#{history}" },
        { role: "user", content: "Ask interview question number #{next_q}." }
      ]
    )

    @session.messages.create!(
      role: "assistant",
      content: ai.choices[0].message.content
    )

    @session.update!(current_question_number: next_q)
  end

  # -------------------------------------------------
  # END SESSION AT 25
  # -------------------------------------------------
  def finish_session_if_done
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      redirect_to final_report_assistant_session_path(@session)
      return true
    end

    false
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
    params.require(:message).permit(:content)
  end
end
