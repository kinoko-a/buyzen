class ItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @items = current_user.items.order(created_at: :desc)

    if params[:status].present?
      @items = @items.where(status: params[:status])
    end
  end

  def show
    @item = Item.find(params[:id])
    redirect_to items_path, alert: "アイテムが見つかりません" unless @item.user == current_user
  rescue ActiveRecord::RecordNotFound
    redirect_to items_path, alert: "アイテムが見つかりません"
  end

  def new
    @item = Item.new
  end

  def create
    @item = current_user.items.build(item_params)
    choice = params[:cooldown_choice]

    if choice == 'skip'
      @item.skip_cooldown!
    elsif choice.present? && Item.cooldown_durations.key?(choice)
      @item.cooldown_duration = choice
    end

    if @item.save
      if choice == 'skip'
        # ! 後で変更(クールダウンスキップ時は購入判断画面に遷移) !
        redirect_to item_path(@item), flash: { success: t('flash.items.create.success') }
      else
        # クールダウンタイマー使用時はアイテム詳細画面に遷移
        redirect_to item_path(@item), flash: { success: t('flash.items.create.success') }
      end
    else
      flash.now[:alert] = t('flash.items.create.failure')
      render :new, status: :unprocessable_entity
    end
  end

  def update;end

  def edit;end

  def destroy;end

  private

  def ensure_ready_for_decision
    redirect_to items_path, alert: "まだ次のステップに進めません" unless @item.ready_for_decision?
  end

  def item_params
    params.require(:item).permit(:name, :note, :cooldown_duration)
  end
end
