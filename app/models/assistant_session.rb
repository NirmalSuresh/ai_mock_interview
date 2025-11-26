class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  def expired?
    Time.current > ends_at
  end

  def time_left_in_seconds
    return 0 if expired?
    (ends_at - Time.current).to_i
  end

  def time_left
    seconds = time_left_in_seconds
    m = seconds / 60
    s = seconds % 60
    "#{format('%02d', m)}:#{format('%02d', s)}"
  end
end
