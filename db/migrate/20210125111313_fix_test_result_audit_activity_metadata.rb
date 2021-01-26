class FixTestResultAuditActivityMetadata < ActiveRecord::Migration[6.1]
  def up
    AuditActivity::Test::Result.all.each do |activity|
      test_result_id = activity.metadata["test_result_id"]
      test_result = Test::Result.find(test_result_id)

      new_metadata = AuditActivity::Test::Result.build_metadata(test_result)

      activity.metadata = rewind_metadata_changes(new_metadata)
      activity.save!
    end
  end

  def down
    AuditActivity::Test::Result.all.each do |activity|
      activity.metadata = { test_result_id: activity.metadata["test_result"]["id"] }
      activity.save!
    end
  end

  def rewind_metadata_changes(new_metadata)
    updated_activities = AuditActivity::Test::TestResultUpdated.where("metadata->>'test_result_id' = ?", new_metadata["test_result"]["id"].to_s).order(created_at: :desc)

    updated_activities.each do |activity|
      activity.metadata["updates"].except("filename", "file_description").each_pair do |attribute, values|
        new_metadata["test_result"][attribute] = values.first
      end

      if activity.metadata["updates"]["filename"].present?
        new_metadata["test_result"]["document"] = get_blob_metadata_by_filename(activity.metadata["updates"]["filename"].first)
      end

      if activity.metadata["updates"]["file_description"].present?
        new_metadata["test_result"]["document"]["metadata"]["description"] = activity.metadata["updates"]["file_description"].first
      end
    end

    new_metadata
  end

  def get_blob_metadata_by_filename(filename)
    blobs = ActiveStorage::Blob.where(filename: filename)

    raise "Ambiguous file match or file not found: #{filename} (blobs.size matches)" unless blobs.size == 1

    blobs.first.attributes
  end
end
