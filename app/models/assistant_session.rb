class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  def expired?
    ends_at.present? && Time.current > ends_at
  end

  def completed?
    status == "completed"
  end

  def time_left
    return 0 unless ends_at.present?
    remaining = (ends_at - Time.current).to_i
    remaining.positive? ? remaining : 0
  end
end
