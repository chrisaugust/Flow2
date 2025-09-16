class MonthlyReviewSerializer
  def initialize(monthly_review)
    @review = monthly_review
  end

  def as_json(_options = {})
    {
      id: @review.id,
      month_start: @review.month_start,
      month_code: @review.month_code,
      total_income: @review.total_income.to_f,
      total_expenses: @review.total_expenses.to_f,
      total_life_energy_hours: @review.total_life_energy_hours.to_f,
      completed: @review.completed,
      notes: @review.notes,
      created_at: @review.created_at,
      updated_at: @review.updated_at,
      user: user_hash,
      monthly_category_reviews: monthly_category_reviews_hash
    }
  end

  private

  def user_hash
    return unless @review.user

    {
      id: @review.user.id,
      email: @review.user.email,
      hourly_wage: @review.user.hourly_wage.to_f
    }
  end

  def monthly_category_reviews_hash
    @review.monthly_category_reviews.map do |mcr|
      {
        id: mcr.id,
        category_id: mcr.category_id,
        month_start: mcr.month_start,
        total_spent: mcr.total_spent.to_f,
        total_life_energy_hours: mcr.total_life_energy_hours.to_f,
        received_fulfillment: mcr.received_fulfillment,
        aligned_with_values: mcr.aligned_with_values,
        would_change_post_fi: mcr.would_change_post_fi,
        created_at: mcr.created_at,
        updated_at: mcr.updated_at
      }
    end
  end
end