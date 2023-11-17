class AddEntityToPaperTrailVersions < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :versions, bulk: true do |t|
        t.string :entity_type
        t.string :entity_id
      end
    end
  end
end
