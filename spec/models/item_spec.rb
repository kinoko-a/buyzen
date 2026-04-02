require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:user) { create(:user) }

  describe "バリデーション" do
    it "アイテム名、ユーザー、クールダウン選択があれば有効である" do
      item = build(:item, user: user)
      item.skip_cooldown!
      expect(item).to be_valid
    end

    it "ユーザーがいない場合無効" do
      item = build(:item, user: nil)
      item.skip_cooldown!
      expect(item).not_to be_valid
    end

    it "アイテム名が空の場合無効" do
      item = build(:item, name: nil)
      item.skip_cooldown!
      item.valid?
      expect(item.errors[:name]).to include("を入力してください")
    end

    it "クールダウン選択がない場合無効" do
      item = build(:item, user: user)
      item.valid?
      expect(item.errors[:cooldown_duration]).to include("を選択してください")
    end
  end

  describe "enum" do
    it "statusが正しく定義されている" do
      expect(Item.statuses.keys).to contain_exactly("thinking", "decided_buy", "decided_skip")
    end

    it "初期状態はthinkingである" do
      item = build(:item, user: user)
      item.skip_cooldown!
      item.save!
      expect(item.status).to eq "thinking"
    end
  end
end
