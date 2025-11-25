class AssistantSession < ApplicationRecord
  belongs_to :user

  # Each session has many answers from the user
  has_many :answers, dependent: :destroy

  # Store all 25 questions inside the model
  def questions
    [
      { number: 1,  content: "Tell me about yourself." },
      { number: 2,  content: "What are your strengths?" },
      { number: 3,  content: "What are your weaknesses?" },
      { number: 4,  content: "Why do you want this job?" },
      { number: 5,  content: "Tell me about a challenge you faced." },
      { number: 6,  content: "Where do you see yourself in 5 years?" },
      { number: 7,  content: "Why should we hire you?" },
      { number: 8,  content: "Tell me about a successful project you worked on." },
      { number: 9,  content: "How do you handle pressure?" },
      { number: 10, content: "What motivates you?" },
      { number: 11, content: "What is your biggest achievement?" },
      { number: 12, content: "How do you prioritize tasks?" },
      { number: 13, content: "Tell me about a conflict you resolved." },
      { number: 14, content: "What do you know about our company?" },
      { number: 15, content: "What are your career goals?" },
      { number: 16, content: "How do you approach learning new skills?" },
      { number: 17, content: "Describe your ideal work environment." },
      { number: 18, content: "Tell me about a time you failed." },
      { number: 19, content: "How do you handle feedback?" },
      { number: 20, content: "What is your leadership style?" },
      { number: 21, content: "Do you prefer teamwork or solo work?" },
      { number: 22, content: "How do you deal with tight deadlines?" },
      { number: 23, content: "Describe a time you went above and beyond." },
      { number: 24, content: "What are your salary expectations?" },
      { number: 25, content: "Do you have any questions for us?" }
    ]
  end
end
