class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :field_name
      t.string :field_value
    end
  end
end
