class CreateAwsData < ActiveRecord::Migration
  def change
    create_table :aws_data do |t|
      t.string :type
      t.string :region
      t.text :data

      t.timestamps null: false
    end
  end
end
