class Message < ApplicationRecord
  belongs_to :assistant_session

  validates :role, presence: true
  validates :content, presence: true
end
