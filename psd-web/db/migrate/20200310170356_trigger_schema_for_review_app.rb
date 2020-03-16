class TriggerSchemaForReviewApp < ActiveRecord::Migration[5.2]
  def change
    # Not the most elegant way, but works. To prevent clash with `keycloak-replacement` review apps DBs, update schema version
  end
end
