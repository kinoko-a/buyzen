require 'rails_helper'

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "nameがあれば有効" do
      user = User.new(
        name: "テストユーザー",
        email: "test@example.com",
        password: "password1",
        password_confirmation: "password1"
      )
      expect(user).to be_valid
    end

    it "nameがないと無効" do
      user = User.new(name: nil)
      user.valid?
      expect(user.errors[:name]).to include("を入力してください")
    end

    it "nameが30文字以内なら有効" do
      user = User.new(name: "a" * 30)
      user.valid?
      expect(user.errors[:name]).to be_empty
    end

    it "nameが31文字以上だと無効" do
      user = User.new(name: "a" * 31)
      user.valid?
      expect(user.errors[:name]).to include("は30文字以内で入力してください")
    end
  end
end
