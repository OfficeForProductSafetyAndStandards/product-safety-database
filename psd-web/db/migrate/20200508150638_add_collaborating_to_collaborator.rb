class AddCollaboratingToCollaborator < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :collaborators do |t|
        t.references :collaborating, polymorphic: true, type: :uuid
      end
    end
  end
end
