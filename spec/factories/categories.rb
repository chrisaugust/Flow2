FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    is_default { false }
    association :user
  end
end