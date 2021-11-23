class BlobCategorizer
  def initialize(blob)
    @blob = blob
  end

  def non_activity_parent
    @blob.attachments.where.not(record_type: "Activity").first
  end

  def is_an_image?
    non_activity_parent.content_type.include?("image")
  end

  def related_investigation
    klass = Object.const_get(non_activity_parent.record_type)
    instance_of_klass = klass.find(non_activity_parent.record_id)
    
    return if instance_of_klass.is_a?(Product)

    instance_of_klass.is_a?(Investigation) ? instance_of_klass : instance_of_klass.investigation
  end
end
