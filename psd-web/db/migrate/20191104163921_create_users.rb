class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users, id: "uuid", default: nil do |t|
      t.string :name
      t.string :email
      t.belongs_to :organisation, type: :uuid
      t.timestamps
    end
  end
end
