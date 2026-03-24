require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  describe "GET /dashboards" do
    it "returns http success" do
      get dashboards_path
      expect(response).to have_http_status(:success)
    end
  end
end
