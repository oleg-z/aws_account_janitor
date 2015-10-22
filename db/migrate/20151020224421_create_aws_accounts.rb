class CreateAwsAccounts < ActiveRecord::Migration
  def change
    create_table :aws_accounts do |t|
      t.string :alias
      t.string :access_key
      t.string :secret_key
      t.string :role

      t.timestamps null: false
    end
  end
end
