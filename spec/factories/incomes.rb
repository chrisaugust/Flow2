FactoryBot.define do
  factory :income do
    amount { 1000.00 }
    association :user
  end
end