class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  # ❌ REMOVE ANY validation requiring title
  # validates :title, presence: true   ← MUST NOT EXIST

  # The session has no required fields, so creation works:
  # current_user.assistant_sessions.create!
end
