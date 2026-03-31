class Item < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :note, length: { maximum: 65_535 }

  enum :status, { thinking: 0, decided_buy: 1, decided_skip: 2 }
  enum :cooldown_duration, { minutes_30: 0, hours_24: 1, days_3: 2 }

  belongs_to :user

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

  def next_action
    case status
    when "thinking"
      if cooldown_not_selected?
        { label: "クールダウン設定", path: "#" }
      elsif ready_for_decision?
        { label: "判断する", path: "#" }
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
end
