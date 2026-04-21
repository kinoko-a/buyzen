class Journal < ApplicationRecord
  validates :content, length: { maximum: 65_535 }
  validates :is_draft, inclusion: { in: [ true, false ] }
  validate :only_one_draft_per_item

  belongs_to :item

  scope :published, -> { where(is_draft: false) }

  def only_one_draft_per_item
    return unless is_draft

    if item.journals.where(is_draft: true).where.not(id: id).exists? # 自分以外にdraftが存在するか？
      errors.add(:base, "下書きは1件まで保存可能です")
    end
  end
end
