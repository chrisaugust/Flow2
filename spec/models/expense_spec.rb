require 'rails_helper'

RSpec.describe Expense, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:category) }
  end

  describe 'validations' do
    context 'recommended validations' do
      let(:expense) { build(:expense) }

      it 'is valid with valid attributes' do
        expect(expense).to be_valid
      end

      it 'should validate presence of amount' do
        expense = build(:expense, amount: nil)
        # This will fail if you don't have the validation
        expense.valid?
        expect(expense.errors[:amount]).to include("can't be blank")
      end

      it 'should validate amount is positive' do
        expense = build(:expense, amount: -10)
        expense.valid?
        expect(expense.errors[:amount]).to include("must be greater than 0")
      end

      it 'should validate presence of occurred_on' do
        expense = build(:expense, occurred_on: nil)
        expense.valid?
        expect(expense.errors[:occurred_on]).to include("can't be blank")
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expense = build(:expense)
      expect(expense).to be_valid
    end

    it 'creates expense with associations' do
      expense = create(:expense)
      expect(expense.user).to be_present
      expect(expense.category).to be_present
      expect(expense.category.user).to eq(expense.user)
    end
  end

  describe 'traits' do
    it 'creates large expense' do
      expense = create(:expense, :large)
      expect(expense.amount).to eq(500.00)
    end

    it 'creates small expense' do
      expense = create(:expense, :small)
      expect(expense.amount).to eq(5.00)
    end

    it 'creates expense from last month' do
      expense = create(:expense, :last_month)
      expect(expense.occurred_on).to eq(1.month.ago.to_date)
    end
  end

  describe 'querying' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }
    
    before do
      create(:expense, user: user, category: category, amount: 100, occurred_on: Date.today)
      create(:expense, user: user, category: category, amount: 200, occurred_on: 1.month.ago)
      create(:expense, user: user, category: category, amount: 50, occurred_on: 1.year.ago)
    end

    it 'filters expenses by date range' do
      start_date = 2.months.ago
      end_date = Date.today
      
      expenses = user.expenses.where(occurred_on: start_date..end_date)
      expect(expenses.count).to eq(2)
    end

    it 'calculates total for a category' do
      total = user.expenses.where(category: category).sum(:amount)
      expect(total).to eq(350)
    end

    it 'groups expenses by category' do
      other_category = create(:category, user: user)
      create(:expense, user: user, category: other_category, amount: 75)
      
      by_category = user.expenses.group(:category_id).sum(:amount)
      expect(by_category[category.id]).to eq(350)
      expect(by_category[other_category.id]).to eq(75)
    end
  end

  describe 'data integrity' do
    let(:user) { create(:user) }
    let(:category) { user.categories.first }
    let!(:expense) { create(:expense, user: user, category: category) }

    it 'is destroyed when user is destroyed' do
      expect { user.destroy }.to change { Expense.count }.by(-1)
    end

    it 'is destroyed when category is destroyed' do
      expect { category.destroy }.to change { Expense.count }.by(-1)
    end

    it 'prevents orphaned expenses' do
      # Expense must belong to both user and category
      orphan_expense = Expense.new(amount: 100, occurred_on: Date.today)
      expect(orphan_expense).not_to be_valid
    end
  end

  describe 'edge cases' do
    it 'handles very large amounts' do
      expense = create(:expense, amount: 999999.99)
      expect(expense.amount).to eq(999999.99)
    end

    it 'handles very small amounts' do
      expense = create(:expense, amount: 0.01)
      expect(expense.amount).to eq(0.01)
    end

    it 'handles dates far in the past' do
      expense = create(:expense, occurred_on: 10.years.ago)
      expect(expense.occurred_on).to eq(10.years.ago.to_date)
    end

    it 'handles dates in the future' do
      expense = create(:expense, occurred_on: 1.month.from_now)
      expect(expense.occurred_on).to eq(1.month.from_now.to_date)
    end

    it 'handles long descriptions' do
      long_description = 'a' * 1000
      expense = create(:expense, description: long_description)
      expect(expense.description).to eq(long_description)
    end

    it 'handles nil description' do
      expense = create(:expense, description: nil)
      expect(expense.description).to be_nil
    end
  end
end