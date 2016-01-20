class AddSpendingThresholdToAwsAccount < ActiveRecord::Migration
  def change
    add_column :aws_accounts, :spending_threshold, :integer
  end
end
