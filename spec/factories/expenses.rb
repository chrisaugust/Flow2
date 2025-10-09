FactoryBot.define do
  factory :expense do
    amount { 100.00 }
    occurred_on { Date.today }
    
    association :user
    association :category
    
    after(:build) do |expense|
      expense.category.user = expense.user
    end

    trait :large do
      amount { 500.00 }
    end

    trait :small do
      amount { 5.00 }
    end

    trait :last_month do
      occurred_on { Date.today.prev_month }
    end
  end
end