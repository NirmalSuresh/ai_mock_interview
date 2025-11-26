class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  def expired?
    ends_at.present? && Time.current > ends_at
  end

  def completed?
    status == "completed"
  end

  def time_left_seconds
    return 0 unless ends_at.present?
    [ends_at - Time.current, 0].max.to_i
  end
end
