class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :questions, dependent: :destroy
  has_many :messages, dependent: :destroy
end
