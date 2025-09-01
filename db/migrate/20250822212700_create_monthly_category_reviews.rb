class CreateMonthlyCategoryReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :monthly_category_reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.date :month_start
      t.decimal :total_spent
      t.decimal :total_life_energy_hours
      t.boolean :received_fulfillment
      t.boolean :aligned_with_values
      t.boolean :would_change_post_fi
      t.string :final_mark

      t.timestamps
    end
  end
end
