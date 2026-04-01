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
    # if params[cooldown_choice] == 'skip'
    #   @item.skip_cooldown!
    # else
    #   @item.cooldown_duration = params[:cooldown_choice]
    # end
  end

  def update;end

  def edit;end

  def destroy;end

  private

  def ensure_ready_for_decision
    redirect_to items_path, alert: "まだ次のステップに進めません" unless @item.ready_for_decision?
  end
end
