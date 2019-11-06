class CreateTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :teams, id: "uuid", default: nil do |t|
      t.string :name
      t.string :path
      t.string :team_recipient_email
      t.belongs_to :organisation, type: :uuid
      t.timestamps

      t.index :name
      t.index :path
    end
  end
end
