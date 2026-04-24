class Journal < ApplicationRecord
  validates :item_id, uniqueness: true
  validates :content, length: { maximum: 65_535 }

  belongs_to :item
end
