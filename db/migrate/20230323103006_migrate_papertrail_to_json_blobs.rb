class MigratePapertrailToJsonBlobs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def self.up
    add_column :versions, :new_object, :jsonb, if_not_exists: true
    add_column :versions, :new_object_changes, :jsonb, if_not_exists: true

    PaperTrail::Version.where.not(object: nil).find_each do |version|
      new_object = Psych.safe_load(version.object, aliases: true, permitted_classes: [Date, Time])
      version.update_column(:new_object, new_object)

      if version.object_changes
        new_object_changes = Psych.safe_load(version.object_changes, aliases: true, permitted_classes: [Date, Time])
        version.update_column(:new_object_changes, new_object_changes)
      end
    end

    safety_assured do
      rename_column :versions, :object, :old_object
      rename_column :versions, :object_changes, :old_object_changes

      rename_column :versions, :new_object, :object
      rename_column :versions, :new_object_changes, :object_changes
    end
  end

  def self.down
    safety_assured do
      remove_column :versions, :object
      remove_column :versions, :object_changes

      rename_column :versions, :old_object, :object
      rename_column :versions, :old_object_changes, :object_changes
    end
  end
end
