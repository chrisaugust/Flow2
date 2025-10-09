FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'SecurePassword123!' }
    password_confirmation { 'SecurePassword123!' }
    hourly_wage { 25.00 }

    trait :without_wage do
      hourly_wage { nil }
    end

    trait :high_earner do
      hourly_wage { 75.00 }
    end
  end
end