class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    items = current_user.items
    @thinking_count     = items.thinking.count
    @decided_buy_count  = items.decided_buy.count
    @decided_skip_count = items.decided_skip.count
  end
end
