require 'rails_helper'

RSpec.describe MonthlyReviewBuilder do
  let(:user) { create(:user, hourly_wage: 25.00) }
  let(:date) { Date.new(2024, 3, 15) }
  let(:builder) { MonthlyReviewBuilder.new(user, date) }

  describe '#build_review' do
    context 'with no existing data' do
      it 'creates a new monthly review' do
        expect { builder.build_review }.to change { MonthlyReview.count }.by(1)
      end

      it 'sets correct month_start' do
        review = builder.build_review
        expect(review.month_start).to eq(Date.new(2024, 3, 1))
      end

      it 'sets correct month_code' do
        review = builder.build_review
        expect(review.month_code).to eq('032024')
      end

      it 'initializes with zero totals when no data exists' do
        review = builder.build_review
        
        expect(review.total_income).to eq(0)
        expect(review.total_expenses).to eq(0)
        expect(review.total_life_energy_hours).to eq(0)
      end
    end

    context 'with existing expenses and income' do
      let(:food_category) { user.categories.find_by(name: 'Food') }
      let(:housing_category) { user.categories.find_by(name: 'Housing') }

      before do
        # Create expenses in target month
        create(:expense, user: user, category: food_category, 
               amount: 200, occurred_on: Date.new(2024, 3, 5))
        create(:expense, user: user, category: food_category, 
               amount: 150, occurred_on: Date.new(2024, 3, 20))
        create(:expense, user: user, category: housing_category, 
               amount: 1200, occurred_on: Date.new(2024, 3, 1))

        # Create income in target month
        create(:income, user: user, amount: 3000, received_on: Date.new(2024, 3, 15))
        create(:income, user: user, amount: 500, received_on: Date.new(2024, 3, 25))

        # Create expenses outside target month (should be ignored)
        create(:expense, user: user, category: food_category, 
               amount: 999, occurred_on: Date.new(2024, 2, 28))
        create(:expense, user: user, category: food_category, 
               amount: 999, occurred_on: Date.new(2024, 4, 1))
      end

      it 'calculates total income correctly' do
        review = builder.build_review
        expect(review.total_income).to eq(3500)
      end

      it 'calculates total expenses correctly' do
        review = builder.build_review
        expect(review.total_expenses).to eq(1550) # 200 + 150 + 1200
      end

      it 'calculates total life energy hours correctly' do
        review = builder.build_review
        # 1550 / 25 = 62 hours
        expect(review.total_life_energy_hours).to eq(62.0)
      end

      it 'creates category reviews for categories with expenses' do
        review = builder.build_review
        
        expect(review.monthly_category_reviews.count).to eq(2)
        
        food_review = review.monthly_category_reviews.find_by(category: food_category)
        expect(food_review.total_spent).to eq(350)
        expect(food_review.total_life_energy_hours).to eq(14.0) # 350 / 25
        
        housing_review = review.monthly_category_reviews.find_by(category: housing_category)
        expect(housing_review.total_spent).to eq(1200)
        expect(housing_review.total_life_energy_hours).to eq(48.0) # 1200 / 25
      end

      it 'does not create category reviews for categories with zero spending' do
        review = builder.build_review
        
        entertainment = user.categories.find_by(name: 'Entertainment')
        entertainment_review = review.monthly_category_reviews.find_by(category: entertainment)
        
        expect(entertainment_review).to be_nil
      end

      it 'excludes expenses from other months' do
        review = builder.build_review
        
        # Should only include March expenses (1550), not February or April (999 each)
        expect(review.total_expenses).to eq(1550)
      end
    end

    context 'when rebuilding existing review' do
      let(:category) { user.categories.first }
      let!(:existing_review) { create(:monthly_review, user: user, month_start: Date.new(2024, 3, 1)) }
      let!(:old_category_review) { create(:monthly_category_review, 
                                          monthly_review: existing_review, 
                                          user: user, 
                                          category: category,
                                          total_spent: 999) }

      before do
        create(:expense, user: user, category: category, 
               amount: 100, occurred_on: Date.new(2024, 3, 15))
      end

      it 'does not create duplicate review' do
        expect { builder.build_review }.not_to change { MonthlyReview.count }
      end

      it 'destroys old category reviews' do
        builder.build_review
        
        expect(MonthlyCategoryReview.find_by(id: old_category_review.id)).to be_nil
      end

      it 'creates fresh category reviews with current data' do
        review = builder.build_review
        
        new_category_review = review.monthly_category_reviews.find_by(category: category)
        expect(new_category_review.total_spent).to eq(100)
        expect(new_category_review.id).not_to eq(old_category_review.id)
      end

      it 'updates totals on existing review' do
        review = builder.build_review
        
        expect(review.id).to eq(existing_review.id)
        expect(review.total_expenses).to eq(100)
      end
    end

    context 'with user without hourly_wage' do
      let(:user_without_wage) { create(:user, :without_wage) }
      let(:builder_no_wage) { MonthlyReviewBuilder.new(user_without_wage, date) }
      let(:category) { user_without_wage.categories.first }

      before do
        create(:expense, user: user_without_wage, category: category, 
               amount: 100, occurred_on: Date.new(2024, 3, 15))
      end

      it 'sets life energy hours to zero' do
        review = builder_no_wage.build_review
        
        expect(review.total_life_energy_hours).to eq(0)
      end

      it 'sets category life energy hours to zero' do
        review = builder_no_wage.build_review
        category_review = review.monthly_category_reviews.first
        
        expect(category_review.total_life_energy_hours).to eq(0)
      end

      it 'still tracks expenses correctly' do
        review = builder_no_wage.build_review
        
        expect(review.total_expenses).to eq(100)
      end
    end

    context 'with user with zero hourly_wage' do
      let(:user_zero_wage) { create(:user, hourly_wage: 0) }
      let(:builder_zero) { MonthlyReviewBuilder.new(user_zero_wage, date) }
      let(:category) { user_zero_wage.categories.first }

      before do
        create(:expense, user: user_zero_wage, category: category, 
               amount: 100, occurred_on: Date.new(2024, 3, 15))
      end

      it 'handles zero wage without division error' do
        expect { builder_zero.build_review }.not_to raise_error
      end

      it 'sets life energy hours to zero' do
        review = builder_zero.build_review
        expect(review.total_life_energy_hours).to eq(0)
      end
    end

    context 'with multiple expenses on same day' do
      let(:category) { user.categories.first }

      before do
        create(:expense, user: user, category: category, 
               amount: 50, occurred_on: Date.new(2024, 3, 15))
        create(:expense, user: user, category: category, 
               amount: 75, occurred_on: Date.new(2024, 3, 15))
        create(:expense, user: user, category: category, 
               amount: 25, occurred_on: Date.new(2024, 3, 15))
      end

      it 'sums all expenses correctly' do
        review = builder.build_review
        expect(review.total_expenses).to eq(150)
      end
    end

    context 'edge cases' do
      it 'handles end-of-month dates correctly' do
        end_of_month_builder = MonthlyReviewBuilder.new(user, Date.new(2024, 3, 31))
        review = end_of_month_builder.build_review
        
        expect(review.month_start).to eq(Date.new(2024, 3, 1))
        expect(review.month_code).to eq('032024')
      end

      it 'handles beginning-of-month dates correctly' do
        start_of_month_builder = MonthlyReviewBuilder.new(user, Date.new(2024, 3, 1))
        review = start_of_month_builder.build_review
        
        expect(review.month_start).to eq(Date.new(2024, 3, 1))
      end

      it 'handles February in leap year' do
        leap_builder = MonthlyReviewBuilder.new(user, Date.new(2024, 2, 29))
        review = leap_builder.build_review
        
        expect(review.month_start).to eq(Date.new(2024, 2, 1))
      end

      it 'handles December correctly' do
        dec_builder = MonthlyReviewBuilder.new(user, Date.new(2024, 12, 15))
        review = dec_builder.build_review
        
        expect(review.month_code).to eq('122024')
      end
    end

    context 'with very small amounts' do
      let(:category) { user.categories.first }

      before do
        create(:expense, user: user, category: category, 
               amount: 0.01, occurred_on: Date.new(2024, 3, 15))
      end

      it 'handles fractional cents' do
        review = builder.build_review
        expect(review.total_expenses).to eq(0.01)
      end

      it 'calculates life energy for small amounts' do
        review = builder.build_review
        # 0.01 / 25 = 0.0004, rounded to 0.0
        expect(review.total_life_energy_hours).to eq(0.0)
      end
    end

    context 'with very large amounts' do
      let(:category) { user.categories.first }

      before do
        create(:expense, user: user, category: category, 
               amount: 999999.99, occurred_on: Date.new(2024, 3, 15))
      end

      it 'handles large expenses' do
        review = builder.build_review
        expect(review.total_expenses).to eq(999999.99)
      end

      it 'calculates life energy for large amounts' do
        review = builder.build_review
        # 999999.99 / 25 = 39999.9996, rounded to 40000.0
        expect(review.total_life_energy_hours).to eq(40000.0)
      end
    end

    context 'with expenses on month boundaries' do
      let(:category) { user.categories.first }

      before do
        # Last day of previous month
        create(:expense, user: user, category: category, 
               amount: 100, occurred_on: Date.new(2024, 2, 29))
        # First day of target month
        create(:expense, user: user, category: category, 
               amount: 200, occurred_on: Date.new(2024, 3, 1))
        # Last day of target month
        create(:expense, user: user, category: category, 
               amount: 300, occurred_on: Date.new(2024, 3, 31))
        # First day of next month
        create(:expense, user: user, category: category, 
               amount: 400, occurred_on: Date.new(2024, 4, 1))
      end

      it 'includes only expenses within month boundaries' do
        review = builder.build_review
        # Should include 200 (3/1) + 300 (3/31) = 500
        expect(review.total_expenses).to eq(500)
      end
    end
  end
end