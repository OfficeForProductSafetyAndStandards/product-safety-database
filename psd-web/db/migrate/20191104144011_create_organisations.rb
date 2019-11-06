class CreateOrganisations < ActiveRecord::Migration[5.2]
  def change
    create_table :organisations, id: "uuid", default: nil do |t|
      t.string :name
      t.string :path
      t.timestamps
    end
  end
end
