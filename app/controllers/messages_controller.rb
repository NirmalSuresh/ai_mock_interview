class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # 1. End if expired
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip.downcase

    # 2. User manually types "end"
    if user_input == "end" || user_input.start_with?("end ")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # 3. Save user message
    @message = @session.messages.create!(
      role: "user",
      content: raw_input.presence,
      attachment: message_params[:attachment]
    )

    # 4. File uploaded → Analyze
    if @message.attachment.attached?
      ai_text = FileAnalyzer.call(@message)

      @session.messages.create!(
        role: "assistant",
        content: ai_text
      )

      generate_next_question!
      return respond_ok
    end

    # 5. Normal text → Ask next question
    generate_next_question!
    respond_ok
  end


  private

  # ===========================================================
  #           FIXED VERSION — NO ARGUMENTS NEEDED
  # ===========================================================
  def generate_next_question!
    return finish_session_if_done

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
        { role: "user", content: "Ask interview question #{next_q}." }
      ]
    )

    @session.messages.create!(
      role: "assistant",
      content: ai.choices[0].message.content
    )

    @session.update!(current_question_number: next_q)
  end


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
    params.require(:message).permit(:content, :attachment)
  end
end
