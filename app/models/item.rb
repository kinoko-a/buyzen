class Item < ApplicationRecord
  before_update :set_decided_at

  validates :name, presence: true, length: { maximum: 255 }
  validates :note, length: { maximum: 65_535 }
  validate :cooldown_choice_valid

  enum :status, { thinking: 0, decided_buy: 1, decided_skip: 2 }
  enum :cooldown_duration, { minutes_30: 0, hours_24: 1, days_3: 2 }

  belongs_to :user
  has_many :journals, dependent: :destroy
  has_many :answers, dependent: :destroy

  # アイテムのステータスを確認
  def cooldown_not_selected?
    cooldown_duration.nil? && cooldown_until.nil?
  end

  def cooldown_skipped?
    cooldown_duration.nil? && cooldown_until.present?
    # クールダウンをスキップ時は、cooldown_untilに現在時刻を入れる
  end

  def cooldown_active?
    cooldown_until.present? && cooldown_until > Time.current
  end

  def cooldown_finished?
    cooldown_until.present? && cooldown_until <= Time.current
  end

  def ready_for_decision?
    cooldown_skipped? || cooldown_finished?
  end

  def decided?
    decided_buy? || decided_skip?
  end

  # ステータスごとに、次のステップを表示
  def next_action
    case status
    when "thinking"
      if cooldown_not_selected?
        { label: "クールダウン設定", type: :cooldown }
      elsif ready_for_decision?
        { label: "判断する", type: :decision }
      end
    end
  end

  def next_action_message
    case status
    when "thinking"
      if cooldown_not_selected?
        "クールダウンタイマーを設定して、次のステップに進みましょう"
      elsif cooldown_active?
        "クールダウンが終わるまで、ひと休みしましょう"
      elsif ready_for_decision?
        "ジャーナリングと購入判断に進むことができます"
      end
    end
  end

  # クールダウンタイマーの時間選択
  def cooldown_options_for_select
    self.class.cooldown_durations.keys.map do |key|
      [ I18n.t("activerecord.enums.item.cooldown_duration.#{key}"), key ]
    end
  end

  # クールダウンタイマーをスキップ(今回は設定しない)
  def skip_cooldown!
    self.cooldown_until = Time.current
    self.cooldown_duration = nil
  end

  def latest_draft_journal
    journals.where(is_draft: true).order(created_at: :desc).first
  end

  private

  def set_decided_at
    self.decided_at = Time.current if decided? && decided_at.nil?
  end

  # アイテム登録時はクールダウン期間の選択が必要
  def cooldown_choice_valid
    if cooldown_duration.blank? && cooldown_until.blank?
      errors.add(:cooldown_duration, "を選択してください")
    end
  end
end
