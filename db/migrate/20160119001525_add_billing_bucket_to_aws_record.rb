class AddBillingBucketToAwsRecord < ActiveRecord::Migration
  def change
    add_column :aws_records, :billing_bucket, :text
  end
end
