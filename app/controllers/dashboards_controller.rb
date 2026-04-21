class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    items = current_user.items.includes(:answers, :journals)

    # 登録済みアイテムをカウント
    @thinking_count     = items.thinking.count
    @decided_buy_count  = items.decided_buy.count
    @decided_skip_count = items.decided_skip.count

    # 今できることの提案（検討中のアイテムをステータスごとに表示）

    # クールダウン中のアイテム
    # スキップ選択時は後からタイマーを使う場合があるため、表示を最優先（クールダウン中は購入判断を行えない）
    cooldown_items_full = items
      .thinking
      .select(&:cooldown_active?)

    cooldown_ids = cooldown_items_full.map(&:id)
    @cooldown_items = cooldown_items_full.last(5)
    @cooldown_items_more = cooldown_items_full.size > 5

    # 下書き中のアイテム
    draft_items_full = items
      .thinking
      .reject { |item| cooldown_ids.include?(item.id) }
      .select { |item| draft_item?(item) }

    draft_ids = draft_items_full.map(&:id)
    @draft_items = draft_items_full.last(5)
    @draft_items_more = draft_items_full.size > 5

    # クールダウンが完了したアイテム
    # 下書き中アイテムとの二重表示を除外
    ready_items_full = items
      .thinking
      .reject { |item| cooldown_ids.include?(item.id) || draft_ids.include?(item.id) }
      .select(&:ready_for_decision?)

    @ready_items = ready_items_full.last(5)
    @ready_items_more = ready_items_full.size > 5
  end

  private

  def draft_item?(item)
    item.journals.any?(&:is_draft) || item.answers.any?(&:is_draft)
  end
end
