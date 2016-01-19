class CreateAwsUsageRecords < ActiveRecord::Migration
  def change
    create_table :aws_usage_records do |t|
      t.string :data_type
      t.string :account_id
      t.date :date
      t.text :data

      t.timestamps null: false
    end
  end
end
