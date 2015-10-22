class AddAccountIdToAwsAccount < ActiveRecord::Migration
  def change
    add_column :aws_accounts, :account_id, :integer
  end
end
