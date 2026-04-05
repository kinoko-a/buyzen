class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :prevent_access_after_decision, only: [:purchase_decision]

  def index
    @items = current_user.items.order(created_at: :desc)

    if params[:status].present?
      @items = @items.where(status: params[:status])
    end
  end

  def show
    @item = Item.find(params[:id])
    redirect_to items_path, alert: t("flash.items.not_found") unless @item.user == current_user
  rescue ActiveRecord::RecordNotFound
    redirect_to items_path, alert: t("flash.items.not_found")
  end

  def new
    @item = Item.new
  end

  def create
    @item = current_user.items.build(item_params)
    choice = params[:cooldown_choice]

    if choice == "skip"
      @item.skip_cooldown!
    elsif choice.present? && Item.cooldown_durations.key?(choice)
      @item.cooldown_duration = choice
    end

    if @item.save
      if choice == "skip"
        # クールダウンスキップ時は購入判断画面に遷移
        redirect_to purchase_decision_item_path(@item), flash: { success: t("flash.items.create.success") }
      else
        # クールダウンタイマー使用時はアイテム詳細画面に遷移
        redirect_to item_path(@item), flash: { success: t("flash.items.create.success") }
      end
    else
      flash.now[:alert] = t("flash.items.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @item = current_user.items.find(params[:id])
  end

  def update
    @item = current_user.items.find(params[:id])
    if @item.update(item_params)
      redirect_to item_path(@item), success: t("flash.items.update.success")
    else
      flash.now[:alert] = t("flash.items.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    item = current_user.items.find(params[:id])
    item.destroy!
    redirect_to items_path, success: t("flash.items.destroy.success")
  rescue ActiveRecord::RecordNotFound
    redirect_to items_path, alert: t("flash.items.not_found")
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to item_path(item), alert: t("flash.items.destroy.failure")
  end

  # フォーム表示用
  def purchase_decision
    @item = current_user.items.find(params[:id])

    @journal = @item.latest_draft_journal || @item.journals.build
  end

  # フォーム送信・保存用
  def submit_decision
    @item = current_user.items.find(params[:id])
    commit_type = params[:commit_type]

    case commit_type

    # 下書き保存
    when "draft"
      save_or_update_draft
      redirect_to item_path(@item), success: t("flash.items.decide.success.draft")

    # 購入判断完了
    when "complete"
      status_params = params.dig(:item, :status)

      if status_params.blank?
        # バリデーションエラー(購入判断完了時は「買う・買わない」の選択が必要)
        @item.errors.add(:status, t("flash.items.decide.validation.status_required"))
        build_journal_from_params
        flash.now[:alert] = t("flash.items.decide.failure")
        render :purchase_decision, status: :unprocessable_entity
      else
        # バリデーションOK(購入判断「買う・買わない」を選択済み)
        if @item.update(status: status_params)
          finalize_journal
          redirect_to dashboards_path, success: t("flash.items.decide.success.complete")
        else
          build_journal_from_params
          flash.now[:alert] = t("flash.items.decide.failure")
          render :purchase_decision, status: :unprocessable_entity
        end
      end
    end
  end

  private

  # クールダウンタイマー実装時に使用
  def ensure_ready_for_decision
    redirect_to items_path, alert: "まだ次のステップに進めません" unless @item.ready_for_decision?
  end

  # 下書き保存
  def save_or_update_draft
    return if journal_content.blank?

    draft_journal = @item.latest_draft_journal

    if draft_journal.present?
      # 下書きがある場合は更新
      draft_journal.update!(content: journal_content)
    else
      # 下書きが無い場合は新規作成
      @item.journals.create!(
        content: journal_content,
        is_draft: true
      )
    end
  end

  # 購入判断完了ボタンをクリック後、バリデーションOK
  def finalize_journal
    return if journal_content.blank?

    draft_journal = @item.latest_draft_journal

    if draft_journal.present?
      # 下書きがある場合は更新
      draft_journal.update!(
        content: journal_content,
        is_draft: false
      )
      # 古い下書きを削除
      @item.journals.where(is_draft: true).where.not(id: draft_journal.id).destroy_all
    else

      # 下書きが無い場合は新規作成
      draft_journal = @item.journals.create!(
        content: journal_content,
        is_draft: false
      )
    end
  end

  def build_journal_from_params
    @journal = Journal.new(
      content: journal_content
    )
  end

  # 購入判断済みの場合はリダイレクト
  def prevent_access_after_decision
    @item = current_user.items.find(params[:id])
    if @item.decided?
      redirect_to item_path(@item), alert: t("flash.items.decide.access_denied.after_decision")
    end
  end

  def item_params
    params.require(:item).permit(
      :name, :note, :cooldown_duration, :status, :journal_content
      )
  end

  def journal_content
    params.dig(:item, :journal_content)
  end
end
