require 'rails_helper'

RSpec.describe "Items", type: :request do
  let(:user) { create(:user) }

  describe "GET /index" do
    context "ログイン後" do
      before { sign_in user }

      it "アイテム一覧画面に遷移できる" do
        get items_path
        expect(response).to have_http_status(:success)
      end

      it "アイテム表示" do
        item = create(:item, user: user, name: "テストアイテム")
        get items_path
        expect(response.body).to include("テストアイテム")
      end
    end

    context "ログイン前" do
      it "アイテム一覧画面に遷移できない" do
        get items_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
