class JournalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item, only: [ :edit, :update ]
  before_action :set_journal, only: [ :edit, :update ]
  before_action :ensure_after_decision, only: [ :edit, :update ]

  def edit; end

  def update
    if journal_content.blank?
      @journal.destroy if @journal.persisted?
    else
      @journal.assign_attributes(content: journal_content)
      @journal.save!
    end

    redirect_to item_path(@item), success: t("flash.journals.update.success")

  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = t("flash.journals.update.failure")
    render :edit, status: :unprocessable_entity
  end

  private

  def set_item
    @item = current_user.items.find(params[:item_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to items_path, alert: t("flash.items.not_found")
  end

  def set_journal
    @journal = @item.journal || @item.build_journal
  end

  def journal_content
    params.dig(:journal, :content)
  end

  # 購入判断完了後のみ遷移できる
  def ensure_after_decision
    return if @item.decided?

    redirect_to item_path(@item), alert: t("flash.journals.access_denied")
  end
end
