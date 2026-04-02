require 'rails_helper'

RSpec.describe "Items", type: :request do
  let(:user) { create(:user) }
  let!(:item) { create(:item, :skip_cooldown, user: user) }

  describe "ログイン済みの場合" do
    before { sign_in user }

    describe "GET /items" do
      it "アイテム一覧画面に遷移できる" do
        get items_path
        expect(response).to have_http_status(:success)
      end

      it "アイテム一覧に自分のアイテムのみ表示される" do
        my_item = build(:item, user: user, name: "自分のアイテム")
        my_item.skip_cooldown!
        my_item.save!
        other_user = create(:user)
        other_item = build(:item, user: other_user, name: "他人のアイテム")
        other_item.skip_cooldown!
        other_item.save!

        get items_path
        expect(response.body).to include("自分のアイテム")
        expect(response.body).not_to include("他人のアイテム")
      end
    end

    describe "GET /items/:id" do
      it "アイテム詳細画面に遷移できる" do
        get item_path(item)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(item.name)
      end

      it "他人のアイテム詳細画面にはアクセスできない" do
        other_user = create(:user)
        other_item = build(:item, user: other_user, name: "他人のアイテム")
        other_item.skip_cooldown!
        other_item.save!

        get item_path(other_item)
        expect(response).to redirect_to(items_path)
      end

      it "存在しないIDの場合リダイレクトされる" do
        get item_path(999999)
        expect(response).to redirect_to(items_path)
      end
    end

    describe "GET /items/new" do
      it "アイテム登録画面に遷移できる" do
        get new_item_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /items/:id" do
      it "自分のアイテムを更新できる" do
        patch item_path(item), params: {
          item: { name: "更新後アイテム" }
        }

        expect(item.reload.name).to eq "更新後アイテム"
      end

      it "更新後はアイテム詳細画面にリダイレクトされる" do
        patch item_path(item), params: {
          item: { name: "更新後アイテム" }
        }

        expect(response).to redirect_to(item_path(item))
      end

      it "他人のアイテムは更新できない" do
        other_user = create(:user)
        other_item = build(:item, user: other_user, name: "他人のアイテム")
        other_item.skip_cooldown!
        other_item.save!

        patch item_path(other_item), params: {
          item: { name: "不正更新" }
        }

        expect(other_item.reload.name).not_to eq "不正更新"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE /items/:id" do
      it "自分のアイテムを削除できる" do
        expect {
          delete item_path(item)
        }.to change(Item, :count).by(-1)
        expect(response).to redirect_to(items_path)
      end

      it "他人のアイテムは削除できない" do
        other_user = create(:user)
        other_item = build(:item, user: other_user, name: "他人のアイテム")
        other_item.skip_cooldown!
        other_item.save!

        expect {
          delete item_path(other_item)
        }.not_to change(Item, :count)
        expect(response).to redirect_to(items_path)
      end

      it "存在しないIDはリダイレクトされる" do
        expect {
          delete item_path(999999)
        }.not_to change(Item, :count)
        expect(response).to redirect_to(items_path)
      end
    end
  end

  describe "ログイン前の場合" do
    it "アイテム一覧画面にアクセスできない" do
      get items_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "アイテム詳細画面にアクセスできない" do
      get item_path(item)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "アイテム登録画面にアクセスできない" do
      get new_item_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
