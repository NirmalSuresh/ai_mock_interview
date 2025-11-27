class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  # ------------------------
  # STATUS HELPERS
  # ------------------------
  def expired?
    ends_at.present? && Time.current > ends_at
  end

  def completed?
    status == "completed"
  end

  def in_progress?
    status == "in_progress"
  end

  # ------------------------
  # TIME HELPERS
  # ------------------------
  def time_left
    return 0 unless ends_at.present?
    remaining = (ends_at - Time.current).to_i
    remaining.positive? ? remaining : 0
  end

  def duration_in_minutes
    return nil unless started_at && ends_at
    ((ends_at - started_at) / 60.0).round
  end

  # ------------------------
  # QUESTION PROGRESS HELPERS
  # ------------------------
  def remaining_questions
    25 - current_question_number.to_i
  end

  def complete!
    update!(status: "completed")
  end
end
