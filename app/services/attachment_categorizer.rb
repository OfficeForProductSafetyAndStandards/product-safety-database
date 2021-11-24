class AttachmentCategorizer
  def initialize(blob)
    @blob = blob
  end

  def non_activity_attachment
    @blob.attachments.where.not(record_type: "Activity").first
  end

  def is_an_image?
    non_activity_attachment.content_type.include?("image")
  end

  def related_investigation
    klass = Object.const_get(non_activity_attachment.record_type)
    instance_of_klass = klass.find(non_activity_attachment.record_id)

    return instance_of_klass if instance_of_klass.is_a?(Investigation)

    instance_of_klass.try(:investigation)
  end
end
