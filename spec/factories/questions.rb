FactoryBot.define do
  factory :question do
    user { nil }
    content { "MyText" }
    position { 1 }
  end
end
