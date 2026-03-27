require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET / (root_path)" do
    context "未ログインユーザー" do
      it "ホーム画面が表示される" do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("買う前に、", "ひと呼吸。") # 適宜ホーム画面のテキストに置き換え
      end
    end

    context "ログイン済みユーザー" do
      let(:user) { User.create!(name: "Test", email: "test@example.com", password: "password1") }

      it "ダッシュボードにリダイレクトされる" do
        sign_in user
        get root_path
        expect(response).to redirect_to(dashboards_path)
      end
    end
  end
end
