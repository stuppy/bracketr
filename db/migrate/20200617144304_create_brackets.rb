class CreateBrackets < ActiveRecord::Migration[5.2]
  def change
    create_table :brackets do |t|
      t.string :name
      t.string :description
      t.string :created_by
      t.json :data

      t.timestamps
    end
  end
end
