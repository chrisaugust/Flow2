FactoryBot.define do
  factory :monthly_review do
    association :user
    
    month_start { Date.today.beginning_of_month }
    total_income { 3000.00 }
    total_expenses { 2500.00 }
    total_life_energy_hours { 100.0 }
    completed { false }
    notes { nil }

    # month_code is set by before_validation callback
    # but we can override if needed

    trait :completed do
      completed { true }
      notes { "Good month overall" }
    end

    trait :last_month do
      month_start { 1.month.ago.beginning_of_month }
      month_code { 1.month.ago.beginning_of_month.strftime('%m%Y') }
    end

    trait :last_year do
      month_start { 1.year.ago.beginning_of_month }
      month_code { 1.year.ago.beginning_of_month.strftime('%m%Y') }
    end

    trait :high_spending do
      total_expenses { 5000.00 }
      total_income { 3000.00 }
    end

    trait :high_saving do
      total_expenses { 1500.00 }
      total_income { 4000.00 }
    end
  end
end