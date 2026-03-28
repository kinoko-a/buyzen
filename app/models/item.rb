class Item < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :thinking_note, length: { maximum: 65_535 }

  enum :status, { thinking: 0, decided_buy: 1, decided_skip: 2 }
  enum :cooldown_duration, { minutes_30: 0, hours_24: 1, days_3: 2 }

  belongs_to :user
end
