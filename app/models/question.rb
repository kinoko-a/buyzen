class Question < ApplicationRecord
  validates :position, presence: true, uniqueness: { scope: :user_id }
  validates :content, presence: true

  belongs_to :user, optional: true
  has_many :answers, dependent: :destroy
end
