class MigratePapertrailToJsonBlobs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def self.up
    add_column :versions, :new_object, :jsonb
    add_column :versions, :new_object_changes, :jsonb

    PaperTrail::Version.where.not(object: nil).find_each do |version|
      new_object = Psych.safe_load(version.object, permitted_classes: [Date, Time])
      version.update_column(:new_object, new_object)

      if version.object_changes
        new_object_changes = Psych.safe_load(version.object_changes, permitted_classes: [Date, Time])
        version.update_column(:new_object_changes, new_object_changes)
      end
    end

    safety_assured do
      remove_column :versions, :object
      remove_column :versions, :object_changes

      rename_column :versions, :new_object, :object
      rename_column :versions, :new_object_changes, :object_changes
    end
  end

  def self.down
    add_column :versions, :new_object, :text
    add_column :versions, :new_object_changes, :text

    PaperTrail::Version.where.not(object: nil).find_each do |version|
      version.update_column(:new_object, version.object.to_yaml)

      if version.object_changes
        version.update_column(
          :new_object_changes,
          version.object_changes.to_yaml
        )
      end
    end

    safety_assured do
      remove_column :versions, :object
      remove_column :versions, :object_changes

      rename_column :versions, :new_object, :object
      rename_column :versions, :new_object_changes, :object_changes
    end
  end
end
