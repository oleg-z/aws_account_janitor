class AddAccountIdToAwsRecord < ActiveRecord::Migration
  def change
    add_column :aws_records, :account_id, :integer
  end
end
