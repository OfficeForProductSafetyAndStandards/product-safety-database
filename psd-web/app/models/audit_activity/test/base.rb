class AuditActivity::Test::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  validates :product, presence: true

  private_class_method def self.from(test, title)
    activity = create(
      body: build_body(test),
      title: title,
      source: UserSource.new(user: User.current),
      investigation: test.investigation,
      product: test.product
    )
    activity.attach_blob test.documents.first.blob if test.documents.attached?
  end

  def self.build_body(test)
    body = ""
    body += "Legislation: **#{sanitize_text(test.legislation)}**<br>" if test.legislation.present?
    body += "#{date_label}: **#{test.date.strftime('%d/%m/%Y')}**<br>" if test.date.present?
    body += "Attached: **#{sanitize_text test.documents.first.filename}**<br>" if test.documents.attached?
    body += "<br>#{sanitize_text(test.details)}" if test.details.present?
    body
  end

  def self.date_label; end

  def activity_type
    "test"
  end
end
