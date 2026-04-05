FactoryBot.define do
  factory :answer do
    item { nil }
    question { nil }
    choice { 1 }
    is_draft { false }
  end
end
