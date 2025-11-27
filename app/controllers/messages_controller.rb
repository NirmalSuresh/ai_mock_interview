class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip.downcase

    if user_input.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.create!(
      role: "user",
      content: raw_input.presence,
      attachment: message_params[:attachment]
    )

    if @message.attachment.attached?
      ai_text = FileAnalyzer.call(@message)

      @session.messages.create!(
        role: "assistant",
        content: ai_text
      )

      generate_next_question!
      return respond_ok
    end

    generate_next_question!
    respond_ok
  end

  private

  def generate_next_question!
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return
    end

    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10).map do |m|
      "#{m.role.capitalize}: #{m.content}"
    end.join("\n")

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    response = client.chat.completions.create(
      model: "llama-3.1-70b-versatile",
      messages: [
        { role: "system", content: SystemPrompt.text },
        { role: "user", content: "Role: #{@session.role}" },
        { role: "user", content: "Conversation:\n#{history}" },
        { role: "user", content: "Ask interview question number #{next_q}." }
      ]
    )

    @session.messages.create!(
      role: "assistant",
      content: response.choices[0].message["content"]
    )

    @session.update!(current_question_number: next_q)
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
