require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { User.create!(name: "Test", email: "test@example.com", password: "password1") }

  describe "GET /dashboards" do
    it "ログイン後はダッシュボードに遷移できる" do
      sign_in user

      get dashboards_path
      expect(response).to have_http_status(:success)
    end

    it "未ログイン時はログイン画面に遷移する" do
      get dashboards_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
