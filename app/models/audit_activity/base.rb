class AuditActivity::Base < Activity
  belongs_to :product, class_name: "::Product", optional: true

  def activity_type
    # where necessary should be implemented by subclasses
    "activity"
  end
end
