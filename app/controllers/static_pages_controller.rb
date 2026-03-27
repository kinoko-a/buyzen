class StaticPagesController < ApplicationController
  def top
    redirect_to dashboards_path if user_signed_in?
  end
end
