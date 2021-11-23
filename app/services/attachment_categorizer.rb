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

    instance_of_klass.is_a?(Investigation) ? instance_of_klass : instance_of_klass.investigation
  rescue NoMethodError
    # if instance_of_klass does not implement #investigation then we do not need to return an investigation.
  end
end
