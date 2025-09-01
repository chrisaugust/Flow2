class RefactorMonthlyCategoryReviews < ActiveRecord::Migration[7.1]
  def up
    remove_column :monthly_category_reviews, :final_mark if column_exists?(:monthly_category_reviews, :final_mark)

    # Drop the old boolean columns
    remove_column :monthly_category_reviews, :received_fulfillment if column_exists?(:monthly_category_reviews, :received_fulfillment)
    remove_column :monthly_category_reviews, :aligned_with_values if column_exists?(:monthly_category_reviews, :aligned_with_values)
    remove_column :monthly_category_reviews, :would_change_post_fi if column_exists?(:monthly_category_reviews, :would_change_post_fi)

    # Create enum type
    execute <<-SQL
      CREATE TYPE mark_enum AS ENUM ('-', '+', '0');
    SQL

    # Add new enum columns
    add_column :monthly_category_reviews, :received_fulfillment, :mark_enum, default: '0', null: false
    add_column :monthly_category_reviews, :aligned_with_values, :mark_enum, default: '0', null: false
    add_column :monthly_category_reviews, :would_change_post_fi, :mark_enum, default: '0', null: false
  end

  def down
    remove_column :monthly_category_reviews, :received_fulfillment if column_exists?(:monthly_category_reviews, :received_fulfillment)
    remove_column :monthly_category_reviews, :aligned_with_values if column_exists?(:monthly_category_reviews, :aligned_with_values)
    remove_column :monthly_category_reviews, :would_change_post_fi if column_exists?(:monthly_category_reviews, :would_change_post_fi)

    execute "DROP TYPE mark_enum;" if execute("SELECT 1 FROM pg_type WHERE typname='mark_enum'").any?

    add_column :monthly_category_reviews, :received_fulfillment, :boolean
    add_column :monthly_category_reviews, :aligned_with_values, :boolean
    add_column :monthly_category_reviews, :would_change_post_fi, :boolean

    add_column :monthly_category_reviews, :final_mark, :string
  end
end
