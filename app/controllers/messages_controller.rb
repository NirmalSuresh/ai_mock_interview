class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # 1. END SESSION MANUALLY
    if params.dig(:message, :content).to_s.strip.downcase == "end"
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # 2. SAVE USER MESSAGE
    @message = @session.messages.create!(
      role: "user",
      content: message_params[:content],
      attachment: message_params[:attachment]
    )

    # 3. IF FILE → ANALYZE & REPLY
    if @message.attachment.attached?
      ai_reply = analyze_file(@message)
      @session.messages.create!(role: "assistant", content: ai_reply)
      generate_next_question
      return respond_ok
    end

    # 4. NORMAL TEXT → NEXT QUESTION
    generate_next_question
    respond_ok
  end

  private

  ###############################################
  # FILE ANALYZER (RubyLLM easy version)
  ###############################################
  def analyze_file(message)
    file = message.attachment
    url  = file.url

    client = RubyLLM::Client.new

    prompt = <<~TEXT
      Analyze the contents of this uploaded file: #{url}
      Extract key points and summarize for interview preparation.
    TEXT

    response = client.chat(
      model: "gpt-4o-mini",
      messages: [
        { role: "user", content: prompt }
      ]
    )

    response["content"]
  rescue => e
    "Error analyzing file: #{e.message}"
  end

  ###############################################
  # GENERATE NEXT QUESTION
  ###############################################
  def generate_next_question
    return finish_if_done

    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10).map do |m|
      "#{m.role}: #{m.content}"
    end.join("\n")

    client = RubyLLM::Client.new

    ai = client.chat(
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: SystemPrompt.text },
        { role: "user", content: "Role: #{@session.role}\n\nConversation:\n#{history}" },
        { role: "user", content: "Ask interview question number #{next_q}." }
      ]
    )

    @session.messages.create!(role: "assistant", content: ai["content"])
    @session.update!(current_question_number: next_q)
  end

  ###############################################
  # END SESSION AT 25 QUESTIONS
  ###############################################
  def finish_if_done
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      redirect_to final_report_assistant_session_path(@session)
    end
  end

  ###############################################
  # RESPONSE HANDLER
  ###############################################
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
