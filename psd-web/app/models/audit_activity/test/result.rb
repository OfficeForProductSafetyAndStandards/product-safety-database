class AuditActivity::Test::Result < AuditActivity::Test::Base
  def self.from(test)
    result_text = test.result == "other" ? "Test result" : test.result.capitalize
    title = "#{result_text} test: #{test.product.name}"
    super(test, title)
  end

  def self.date_label
    "Test date"
  end

  def email_update_text(viewing_user = nil)
    "Test result was added to the #{investigation.case_type} by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "Test result recorded"
  end
end
