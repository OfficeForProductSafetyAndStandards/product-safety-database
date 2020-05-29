namespace :attachments do
  # Will delete investigation attachments with blobs shared with other entities
  # like Communications or Test results.
  # We only want to keep the investigation attachments that were directly added
  # to the investigation itself.
  # 'Activity' record type corresponds to the activity log entry. Activity
  # log entries are registering the attachment being added to the Investigation.
  # When this happen the Activity entry will the same attachment blob as the
  # Investigation.
  desc "Delete activities attachments from investigations"
  task delete_activities_from_investigations: :environment do
    ActiveStorage::Attachment
      .where(record_type: "Investigation")
      .where(
        blob_id: ActiveStorage::Attachment.where.not(record_type: %w[Investigation Activity]).pluck(:blob_id)
      ).delete_all
  end
end
