require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "ユーザー登録" do
    it "有効な情報で登録できる" do
      expect {
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "test@example.com",
            password: "password1",
            password_confirmation: "password1"
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboards_path)
    end

    it "nameがないと登録できない" do
      expect {
        post user_registration_path, params: {
          user: {
            name: "",
            email: "test@example.com",
            password: "password1",
            password_confirmation: "password1"
          }
        }
      }.not_to change(User, :count)
    end
  end

  describe "ログイン" do
    let(:user) {
      User.create!(
        name: "テスト",
        email: "test@example.com",
        password: "password1",
        password_confirmation: "password1"
      )
    }

    it "正しい情報でログインできる" do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password1"
        }
      }

      expect(response).to redirect_to(dashboards_path)
    end

    it "間違ったパスワードだとログインできない" do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "wrongpass"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
