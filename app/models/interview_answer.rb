class InterviewAnswer < ApplicationRecord
  belongs_to :assistant_session

  validates :content, presence: true
  validates :question_number, presence: true
end
