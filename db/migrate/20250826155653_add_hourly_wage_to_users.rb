class AddHourlyWageToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hourly_wage, :decimal, precision: 10, scale: 2
  end
end
