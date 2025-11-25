class AssistantSession < ApplicationRecord
  belongs_to :user
  has_many :answers, dependent: :destroy

  def questions
    [
      { number: 1, content: "Tell me about yourself." },
      { number: 2, content: "What is your strength?" },
      { number: 3, content: "What is your weakness?" },
      { number: 4, content: "Explain OOP in Ruby." },
      { number: 5, content: "What is a class and module?" },
      { number: 6, content: "Explain MVC in Rails." },
      { number: 7, content: "What are migrations?" },
      { number: 8, content: "Explain ActiveRecord." },
      { number: 9, content: "What is polymorphism?" },
      { number: 10, content: "What is dependency injection?" },
      { number: 11, content: "What is REST API?" },
      { number: 12, content: "Explain background jobs." },
      { number: 13, content: "What is Redis used for?" },
      { number: 14, content: "Explain SQL joins." },
      { number: 15, content: "Difference between PUT & PATCH." },
      { number: 16, content: "Explain N+1 query problem." },
      { number: 17, content: "Explain caching." },
      { number: 18, content: "Explain Python vs Ruby." },
      { number: 19, content: "How do you handle errors?" },
      { number: 20, content: "Explain Git workflow." },
      { number: 21, content: "What is CI/CD?" },
      { number: 22, content: "Explain Docker." },
      { number: 23, content: "Explain microservices." },
      { number: 24, content: "Explain scalability." },
      { number: 25, content: "Why should we hire you?" }
    ]
  end
end
