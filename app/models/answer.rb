class Answer < ApplicationRecord
  validates :question_id, uniqueness: { scope: :item_id }

  enum :choice, { yes: 0, unknown: 1, no: 2 }

  belongs_to :item
  belongs_to :question
end
