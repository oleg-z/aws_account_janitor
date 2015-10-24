class AddIdentifierToAwsAccount < ActiveRecord::Migration
  def change
    add_column :aws_accounts, :identifier, :string
  end
end
