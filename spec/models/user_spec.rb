require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:categories).dependent(:destroy) }
    it { should have_many(:expenses).dependent(:destroy) }
    it { should have_many(:incomes).dependent(:destroy) }
    it { should have_many(:monthly_reviews).dependent(:destroy) }
    it { should have_many(:monthly_category_reviews).through(:monthly_reviews) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_numericality_of(:hourly_wage).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'callbacks' do
    context 'after create' do
      it 'creates default categories' do
        user = create(:user)
        
        expect(user.categories.count).to eq(11)
        expect(user.categories.pluck(:name)).to include(
          'Housing', 'Food', 'Transportation', 'Utilities', 
          'Insurance', 'Healthcare', 'Savings', 'Debt', 
          'Personal', 'Entertainment', 'Taxes'
        )
      end

      it 'marks default categories as default' do
        user = create(:user)
        
        expect(user.categories.where(is_default: true).count).to eq(11)
      end
    end
  end

  describe 'dependent destroy behavior' do
    let(:user) { create(:user) }
    let!(:category) { create(:category, user: user, is_default: false) }
    let!(:expense) { create(:expense, user: user, category: category) }
    let!(:income) { create(:income, user: user) }

    it 'destroys associated records when user is destroyed' do
      expect { user.destroy }.to change { Category.count }.by(-12) # 11 default + 1 custom
        .and change { Expense.count }.by(-1)
        .and change { Income.count }.by(-1)
    end
  end

  describe 'hourly_wage' do
    it 'allows nil hourly_wage' do
      user = build(:user, :without_wage)
      expect(user).to be_valid
    end

    it 'allows zero hourly_wage' do
      user = build(:user, hourly_wage: 0)
      expect(user).to be_valid
    end

    it 'rejects negative hourly_wage' do
      user = build(:user, hourly_wage: -10)
      expect(user).not_to be_valid
      expect(user.errors[:hourly_wage]).to include('must be greater than or equal to 0')
    end

    it 'accepts positive hourly_wage' do
      user = build(:user, hourly_wage: 50.00)
      expect(user).to be_valid
    end
  end
end