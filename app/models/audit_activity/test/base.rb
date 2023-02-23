class AuditActivity::Test::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  validates :investigation_product, presence: true

  def activity_type
    "test"
  end
end
