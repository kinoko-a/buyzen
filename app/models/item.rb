class Item < ApplicationRecord
  include ActionView::Helpers::DateHelper

  before_update :set_decided_at
  before_save :set_cooldown_until, if: :will_save_change_to_cooldown_duration?

  validates :name, presence: true, length: { maximum: 255 }
  validates :note, length: { maximum: 65_535 }
  validate :cooldown_choice_valid

  enum :status, { thinking: 0, decided_buy: 1, decided_skip: 2 }
  enum :cooldown_duration, { minutes_30: 0, hours_24: 1, days_3: 2 }

  belongs_to :user
  has_many :journals, dependent: :destroy
  has_many :answers, dependent: :destroy

  scope :cooldown_finished_unnotified, -> {
    where("cooldown_until <= ?", Time.current)
      .where(notified_at: nil)
  }

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

  # 設定したクールダウン期間・完了までの残り時間を表示
  def cooldown_status_text
    if cooldown_active?
      "#{cooldown_duration_text}のクールダウン中 (#{remaining_time_text})"
    elsif cooldown_skipped?
      "クールダウンは設定されていません"
    elsif cooldown_finished?
      "#{cooldown_duration_text}のクールダウンが終わりました"
    end
  end

  def cooldown_duration_text
    I18n.t("activerecord.enums.item.cooldown_duration.#{cooldown_duration}") if cooldown_duration.present?
  end

  def remaining_time_text
    return "" unless cooldown_until

    seconds = (cooldown_until - Time.current).to_i
    return "あと1分" if seconds < 60

    days = (seconds / 1.day.to_f).ceil
    hours = (seconds / 1.hour.to_f).ceil
    minutes = (seconds / 1.minute.to_f).ceil

    if seconds >= 1.days
      # 24時間以上～3日以下 → 切り上げ日表示
      "あと#{days}日"
    elsif seconds >= 1.hour
      # 1時間以上～24時間未満 → 切り上げ時間表示
      "あと#{hours}時間"
    else
      # 1分以上～1時間未満 → 切り上げ分表示
      "あと#{minutes}分"
    end
  end

  # クールダウンタイマーの設定
  # 現在時刻から指定した期間までの時間を取得
  def set_cooldown_until
    return if cooldown_duration.blank?

    self.cooldown_until =
      case cooldown_duration
      when "minutes_30"
        30.minutes.from_now
      when "hours_24"
        24.hours.from_now
      when "days_3"
        3.days.from_now
      end
  end

  # クールダウンタイマーをスキップ(今回は設定しない)
  def skip_cooldown!
    self.cooldown_until = Time.current
    self.cooldown_duration = nil
  end

  # クールダウンタイマー通知済みに変更
  def mark_as_notified!
    update!(notified_at: Time.current)
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
