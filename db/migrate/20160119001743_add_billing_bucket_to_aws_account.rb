class AddBillingBucketToAwsAccount < ActiveRecord::Migration
  def change
    add_column :aws_accounts, :billing_bucket, :text
  end
end
