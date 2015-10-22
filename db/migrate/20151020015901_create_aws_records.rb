class CreateAwsRecords < ActiveRecord::Migration
  def change
    create_table :aws_records do |t|
      t.string :data_type
      t.string :aws_region
      t.text :data

      t.timestamps null: false
    end
  end
end
