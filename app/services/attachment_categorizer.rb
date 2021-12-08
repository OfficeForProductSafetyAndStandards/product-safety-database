class AttachmentCategorizer
  def initialize(blob)
    @blob = blob
  end

  def attachment
    @blob.attachments.first
  end

  def is_an_image?
    attachment.content_type.include?("image")
  end

  def related_activity_type
    return unless attachment.record_type == "Activity"

    Activity.find(attachment.record_id).type
  end

  def related_investigation
    return if attachment.blank?

    klass = Object.const_get(attachment.record_type)

    instance_of_klass = klass.find(attachment.record_id)

    return instance_of_klass if instance_of_klass.is_a?(Investigation)

    instance_of_klass.try(:investigation)
  end

  def is_a_correspondence_activity?
    related_activity_type.try(:include?, "Correspondence")
  end

  def is_an_investigation_document?
    related_activity_type.try(:include?, "AuditActivity::Document")
  end
end
