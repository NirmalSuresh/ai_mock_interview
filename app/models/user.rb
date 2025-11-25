class User < ApplicationRecord
  has_many :assistant_sessions, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
