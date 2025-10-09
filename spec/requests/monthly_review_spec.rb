require 'rails_helper'

RSpec.describe "MonthlyReviews API", type: :request do
  let(:user) { create(:user) }
  let(:token) { JWT.encode({ user_id: user.id }, Rails.application.secrets.secret_key_base) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  describe "GET /monthly_reviews" do
    before do
      create(:monthly_review, user: user, month_start: Date.new(2024, 1, 1))
      create(:monthly_review, user: user, month_start: Date.new(2024, 2, 1))
    end

    context "when authenticated" do
      it "returns all user's monthly reviews" do
        get "/monthly_reviews", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
      end

      it "includes monthly_category_reviews" do
        review = user.monthly_reviews.first
        create(:monthly_category_review, monthly_review: review, user: user)

        get "/monthly_reviews", headers: headers

        json = JSON.parse(response.body)
        expect(json.first).to have_key('monthly_category_reviews')
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        get "/monthly_reviews"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /monthly_reviews/:id" do
    let(:review) { create(:monthly_review, user: user) }
    let!(:category_review) { create(:monthly_category_review, monthly_review: review, user: user) }

    context "when authenticated" do
      it "returns the specific review" do
        get "/monthly_reviews/#{review.id}", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(review.id)
      end

      it "includes associations" do
        get "/monthly_reviews/#{review.id}", headers: headers

        json = JSON.parse(response.body)
        expect(json).to have_key('monthly_category_reviews')
        expect(json).to have_key('user')
      end
    end

    context "when review doesn't exist" do
      it "returns not found" do
        get "/monthly_reviews/99999", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when accessing another user's review" do
      let(:other_user) { create(:user) }
      let(:other_review) { create(:monthly_review, user: other_user) }

      it "returns not found" do
        get "/monthly_reviews/#{other_review.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /monthly_reviews" do
    context "when authenticated" do
      context "with month parameter" do
        it "creates a new review for the specified month" do
          expect {
            post "/monthly_reviews", 
                 params: { month: '2024-03-15' }.to_json,
                 headers: headers
          }.to change { MonthlyReview.count }.by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['month_code']).to eq('032024')
        end
      end

      context "without month parameter" do
        it "creates a review for current month" do
          post "/monthly_reviews", params: {}.to_json, headers: headers

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['month_code']).to eq(Date.today.strftime('%m%Y'))
        end
      end

      context "when review already exists" do
        let!(:existing_review) { create(:monthly_review, user: user, month_start: Date.new(2024, 3, 1)) }

        it "returns existing review without creating duplicate" do
          expect {
            post "/monthly_reviews", 
                 params: { month: '2024-03-15' }.to_json,
                 headers: headers
          }.not_to change { MonthlyReview.count }

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['id']).to eq(existing_review.id)
        end
      end
    end
  end

  describe "POST /monthly_reviews/:id/rebuild" do
    let(:review) { create(:monthly_review, user: user, month_start: Date.new(2024, 1, 1)) }
    let(:category) { user.categories.first }
    
    before do
      create(:monthly_category_review, monthly_review: review, user: user, category: category)
    end

    context "when authenticated" do
      it "rebuilds the review" do
        post "/monthly_reviews/#{review.id}/rebuild", headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "destroys old category reviews" do
        old_category_review_id = review.monthly_category_reviews.first.id

        post "/monthly_reviews/#{review.id}/rebuild", headers: headers

        expect(MonthlyCategoryReview.find_by(id: old_category_review_id)).to be_nil
      end

      it "creates fresh category reviews" do
        # Add some expenses to ensure new category reviews are created
        create(:expense, user: user, category: category, 
               occurred_on: Date.new(2024, 1, 15), amount: 100)

        post "/monthly_reviews/#{review.id}/rebuild", headers: headers

        json = JSON.parse(response.body)
        expect(json['monthly_category_reviews']).to be_present
      end
    end
  end

  describe "PATCH /monthly_reviews/:id/toggle_complete" do
    let(:review) { create(:monthly_review, user: user, completed: false) }

    context "when authenticated" do
      it "marks review as completed" do
        patch "/monthly_reviews/#{review.id}/toggle_complete", headers: headers

        review.reload
        expect(review.completed).to be true
      end

      it "does not toggle already completed review" do
        completed_review = create(:monthly_review, :completed, user: user)

        patch "/monthly_reviews/#{completed_review.id}/toggle_complete", headers: headers

        completed_review.reload
        expect(completed_review.completed).to be true
      end
    end
  end

  describe "GET /monthly_reviews/by_month_code/:month_code" do
    let!(:review) { create(:monthly_review, user: user, month_start: Date.new(2024, 5, 1)) }

    context "when authenticated" do
      it "returns review for specific month code" do
        get "/monthly_reviews/by_month_code/052024", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['month_code']).to eq('052024')
      end
    end

    context "when month code doesn't exist" do
      it "returns not found" do
        get "/monthly_reviews/by_month_code/999999", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /monthly_reviews/:id" do
    let(:review) { create(:monthly_review, user: user, notes: "Old notes", completed: false) }

    context "when authenticated" do
      it "updates notes" do
        patch "/monthly_reviews/#{review.id}",
              params: { monthly_review: { notes: "New reflections" } }.to_json,
              headers: headers

        expect(response).to have_http_status(:ok)
        review.reload
        expect(review.notes).to eq("New reflections")
      end

      it "updates completed status" do
        patch "/monthly_reviews/#{review.id}",
              params: { monthly_review: { completed: true } }.to_json,
              headers: headers

        expect(response).to have_http_status(:ok)
        review.reload
        expect(review.completed).to be true
      end

      it "does not update other attributes" do
        patch "/monthly_reviews/#{review.id}",
              params: { monthly_review: { total_income: 9999 } }.to_json,
              headers: headers

        review.reload
        expect(review.total_income).not_to eq(9999)
      end
    end

    context "with invalid data" do
      it "returns unprocessable entity" do
        errors = ActiveModel::Errors.new(MonthlyReview.new)
        errors.add(:notes, "Error message")

        allow_any_instance_of(MonthlyReview).to receive(:update).and_return(false)
        allow_any_instance_of(MonthlyReview).to receive(:errors).and_return(errors)

        patch "/monthly_reviews/#{review.id}",
              params: { monthly_review: { notes: "test" } }.to_json,
              headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "error handling" do
    context "with StandardError" do
      before do
        allow_any_instance_of(MonthlyReviewsController).to receive(:index).and_raise(StandardError, "Something went wrong")
      end

      it "rescues and returns error" do
        get "/monthly_reviews", headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Something went wrong")
      end
    end
  end
end