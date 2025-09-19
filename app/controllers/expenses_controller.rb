class ExpensesController < ApplicationController
  include AuthHelper
  before_action :authorized_user
  before_action :set_expense, only: [:show, :update, :destroy]

  def index
    expenses = @current_user.expenses.order(occurred_on: :desc)

    if params[:month].present? && params[:year].present?
      expenses = expenses.where("extract(month from occurred_on) = ? AND extract(year from occurred_on) = ?",
                              params[:month].to_i, params[:year].to_i)
    end
    render json: expenses
  end

  def show
    render json: @expense
  end

  def create
    expense = @current_user.expenses.build(expense_params)
    if expense.save
      render json: expense, status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      render json: @expense
    else
      render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    head :no_content
  end

  private

  def set_expense
    @expense = @current_user.expenses.find_by(id: params[:id])
    unless @expense
      render json: { error: 'Expense not found' }, status: :not_found
    end
  end

  def expense_params
    params.require(:expense).permit(:description, :amount, :category_id, :occurred_on)
  end
end
