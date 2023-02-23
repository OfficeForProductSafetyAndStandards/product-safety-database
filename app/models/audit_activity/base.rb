# TODO move all super class methods to this class, remove AuditActivity::Base
# This is the only class that inherits from Activity

class AuditActivity::Base < Activity
  belongs_to :investigation_product, class_name: "::InvestigationProduct", optional: true

  def activity_type
    # where necessary should be implemented by subclasses
    "activity"
  end
end
