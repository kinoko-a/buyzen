require 'rails_helper'

RSpec.describe "Items", type: :request do
  let(:user) { create(:user) }
  let!(:item) { create(:item, :skip_cooldown, user: user) }

  describe "GET /items" do
    context "ログイン後" do
      before { sign_in user }

      it "アイテム一覧画面に遷移できる" do
        get items_path
        expect(response).to have_http_status(:success)
      end

      it "アイテム詳細画面に遷移できる" do
        get item_path(item)
        expect(response).to have_http_status(:success)
      end

      it "アイテム登録画面に遷移できる" do
        get new_item_path
        expect(response).to have_http_status(:success)
      end

      it "アイテムが表示される" do
        get items_path
        expect(response.body).to include(item.name)
        get item_path(item)
        expect(response.body).to include(item.name)
      end

      it "存在しないIDの場合リダイレクトされる" do
        get item_path(999999)
        expect(response).to redirect_to(items_path)
      end

      it "アイテム一覧に他人のアイテムを表示しない" do
        my_item = build(:item, user: user, name: "自分のアイテム")
        my_item.skip_cooldown!
        my_item.save!

        other_user = create(:user)
        other_item = build(:item, user: other_user, name: "他人のアイテム")
        other_item.skip_cooldown!
        other_item.save!

        get items_path
        expect(response.body).to include("自分のアイテム")
        expect(response.body).not_to include(other_item.name)
      end

      it "他人のアイテム詳細にはアクセスできない" do
        other_user = create(:user)
        other_item = build(:item, user: other_user, name: "他人のアイテム")
        other_item.skip_cooldown!
        other_item.save!

        get item_path(other_item)
        expect(response).to redirect_to(items_path)
      end
    end

    context "ログイン前" do
      it "アイテム一覧画面に遷移できない" do
        get items_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "アイテム詳細画面に遷移できない" do
        get item_path(item)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "アイテム登録画面に遷移できない" do
        get new_item_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
