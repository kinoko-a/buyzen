FactoryBot.define do
  factory :item do
    name { "テストアイテム" }
    association :user
    status { :thinking }
  end
end
