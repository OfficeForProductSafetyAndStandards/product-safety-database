class CreateCollaborators < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      create_table :collaborators do |t|
        t.integer :investigation_id, null: false
        t.uuid :team_id, null: false
        t.uuid :added_by_user_id, null: false
        t.text :message

        t.timestamps
      end

      add_foreign_key :collaborators, :investigations
      add_foreign_key :collaborators, :teams
      add_foreign_key :collaborators, :users, column: :added_by_user_id

      add_index :collaborators, %i[investigation_id team_id], unique: true
    end
  end
end
