class MonthlyReviewBuilder
  def initialize(user, date)
    @user = user
    @month_start = date.beginning_of_month
    @month_end = date.end_of_month
    @hourly_wage = user.hourly_wage
    @month_code  = @month_start.strftime('%m%Y')
  end

  def build_review
    review = MonthlyReview.find_or_initialize_by(
      user: @user,
      month_code: @month_code
    )

    # Always reset totals in case we’re rebuilding
    review.assign_attributes(
      month_start: @month_start
    )
    review.save! if review.new_record?

    # Rebuild category reviews each time
    review.monthly_category_reviews.destroy_all

    total_income_for_month = @user.incomes
      .where(received_on: @month_start..@month_end)
      .sum(:amount)

    total_spent_all = 0
    total_hours_all = 0

    @user.categories.each do |category|
      total_spent = category.expenses
        .where(occurred_on: @month_start..@month_end)
        .sum(:amount)

      next if total_spent.zero?

      total_hours = if @hourly_wage&.positive?
        (total_spent.to_f / @hourly_wage).round(2)
      else
        0
      end

      review.monthly_category_reviews.create!(
        user: @user,
        category: category,
        month_start: @month_start,
        total_spent: total_spent,
        total_life_energy_hours: total_hours
      )

      total_spent_all += total_spent
      total_hours_all += total_hours
    end

    review.update!(
      total_income: total_income_for_month,
      total_expenses: total_spent_all,
      total_life_energy_hours: total_hours_all
    )

    review
  end
end