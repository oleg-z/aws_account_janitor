class AddEmailToAwsAccount < ActiveRecord::Migration
  def change
    add_column :aws_accounts, :email, :string
  end
end
