class Answer < ApplicationRecord
  enum choice: { yes: 0, unknown: 1, no: 2 }

  belongs_to :item
  belongs_to :question
end
