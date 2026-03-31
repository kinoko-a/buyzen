FactoryBot.define do
  factory :item do
    name { "テストアイテム" }
    association :user
    status { :thinking }

    trait :with_name do
      sequence(:name) { |n| "テストアイテム#{n}" }
    end
  end
end
