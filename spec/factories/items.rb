FactoryBot.define do
  factory :item do
    name { "テストアイテム" }
    association :user
    status { :thinking }

    trait :with_name do
      sequence(:name) { |n| "テストアイテム#{n}" }
    end

    trait :skip_cooldown do
      after(:build) { |item| item.skip_cooldown! }
    end
  end
end
