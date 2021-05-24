class AuditActivity::Test::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  validates :product, presence: true

  def activity_type
    "test"
  end
end
