class Journal < ApplicationRecord
  validates :is_draft, inclusion: { in: [ true, false ] }

  belongs_to :item

  scope :published, -> { where(is_draft: false) }
end
