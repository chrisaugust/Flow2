class IncomesController < ApplicationController
  include AuthHelper
  before_action :authorized_user
  before_action :set_income, only: [:show, :update, :destroy]

  def index
    @incomes = @current_user.incomes.order(received_on: :desc)
    render json: @incomes
  end

  def show
    render json: @income
  end

  def create
    @income = @current_user.incomes.build(income_params)
    if @income.save
      render json: @income, status: :created
    else
      render json: { errors: @income.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @income.update(income_params)
      render json: @income
    else
      render json: { errors: @income.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @income.destroy
    head :no_content
  end

  private

  def set_income
    @income = @current_user.incomes.find_by(id: params[:id])
    render json: { error: 'Income not found' }, status: :not_found unless @income
    return
  end

  def income_params
    params.require(:income).permit(:source, :amount, :received_on, :is_work_income, :notes)
  end
end
