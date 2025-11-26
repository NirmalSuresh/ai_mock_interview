class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :role, presence: true

  # status: "in_progress" or "completed"

  def completed?
    status == "completed"
  end

  def expired?
    ends_at.present? && Time.current >= ends_at
  end

  def time_left
    return 0 if expired? || ends_at.blank?
    (ends_at - Time.current).to_i
  end
end
