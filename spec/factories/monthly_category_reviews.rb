FactoryBot.define do
  factory :monthly_category_review do
    association :user
    association :category
    association :monthly_review
    
    month_start { Date.today.beginning_of_month }
    total_spent { 250.00 }
    total_life_energy_hours { 10.0 }
    received_fulfillment { "0" }
    aligned_with_values { "0" }
    would_change_post_fi { "0" }

    trait :positive do
      received_fulfillment { "+" }
      aligned_with_values { "+" }
      would_change_post_fi { "-" }
    end

    trait :negative do
      received_fulfillment { "-" }
      aligned_with_values { "-" }
      would_change_post_fi { "+" }
    end

    trait :mixed do
      received_fulfillment { "+" }
      aligned_with_values { "-" }
      would_change_post_fi { "0" }
    end

    trait :high_spending do
      total_spent { 1000.00 }
      total_life_energy_hours { 40.0 }
    end

    trait :low_spending do
      total_spent { 50.00 }
      total_life_energy_hours { 2.0 }
    end
  end
end