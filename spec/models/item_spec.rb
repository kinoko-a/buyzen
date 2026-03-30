require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:user) { create(:user) }

  describe "バリデーション" do
    it "名前とユーザーがあれば有効である" do
      item = build(:item, user: user)
      expect(item).to be_valid
    end
  end

  describe "enum" do
    it "statusが正しく定義されている" do
      expect(Item.statuses.keys).to contain_exactly("thinking", "decided_buy", "decided_skip")
    end

    it "初期状態はthinkingである" do
      item = create(:item, user: user)
      expect(item.status).to eq "thinking"
    end
  end
end
