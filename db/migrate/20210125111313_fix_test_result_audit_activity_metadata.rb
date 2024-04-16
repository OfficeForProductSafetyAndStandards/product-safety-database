class FixTestResultAuditActivityMetadata < ActiveRecord::Migration[6.1]
  def up
    AuditActivity::Test::Result.all.find_each do |activity|
      test_result = resolve_test_result(activity)
      new_metadata = AuditActivity::Test::Result.build_metadata(test_result)

      activity.metadata = rewind_metadata_changes(new_metadata, activity)
      activity.save!
    end
  end

  def down
    AuditActivity::Test::Result.all.find_each do |activity|
      activity.metadata = { test_result_id: activity.metadata["test_result"]["id"] }
      activity.save!
    end
  end

  def resolve_test_result(activity)
    if activity.metadata.present?
      test_result_id = activity.metadata["test_result_id"]
      return Test::Result.find(test_result_id)
    end

    test_result = get_test_result_from_attachment(activity)
    test_result ||= get_only_test_result_from_investigation(activity.investigation)

    test_result
  end

  def get_test_result_from_attachment(activity)
    activity.attachment.blob.attachments.find_by(record_type: "Test")&.record
  end

  def get_only_test_result_from_investigation(investigation)
    investigation.test_results.first if investigation.test_results.one?
  end

  def rewind_metadata_changes(new_metadata, activity)
    updated_activities = AuditActivity::Test::TestResultUpdated.where("metadata->>'test_result_id' = ?", new_metadata["test_result"]["id"].to_s).order(created_at: :desc)
    file_to_find = nil
    file_description = nil

    updated_activities.each do |updated_activity|
      updated_activity.metadata["updates"].except("filename", "file_description").each_pair do |attribute, values|
        new_metadata["test_result"][attribute] = values.first
      end

      if updated_activity.metadata["updates"]["filename"].present?
        file_to_find = updated_activity.metadata["updates"]["filename"].first
      end

      if updated_activity.metadata["updates"]["file_description"].present?
        file_description = updated_activity.metadata["updates"]["file_description"].first
      end
    end

    if file_to_find
      new_metadata["test_result"]["document"] = get_blob_metadata(file_to_find, activity)
    end

    if file_description
      new_metadata["test_result"]["document"]["metadata"]["description"] = file_description
    end

    new_metadata
  end

  def get_blob_metadata(file_to_find, activity)
    if activity.attachment.blob && activity.attachment.blob.filename.to_s == file_to_find
      return activity.attachment.blob.attributes
    end

    get_blob_metadata_by_filename(file_to_find)
  end

  def get_blob_metadata_by_filename(filename)
    blobs = ActiveStorage::Blob.where(filename:)

    raise "Ambiguous file match or file not found: #{filename} (#{blobs.size} matches)" unless blobs.size == 1

    blobs.first.attributes
  end
end
