class AuditActivity::Test::ResultDecorator < ApplicationDecorator
  delegate_all

  def title(_viewing_user = nil)
    return super if metadata.nil?

    # The decorator provides logic to create the title but it may have changed
    # in subsequent edits, so we need to create a new instance using the
    # original attributes in order to decorate it
    Test::Result.new(metadata["test_result"].except("document")).decorate.title
  end

  def standards_product_was_tested_against
    super&.join(", ")
  end

  def date
    super.to_formatted_s(:govuk)
  end

  def result
    super.titleize
  end

  def file_description
    object.metadata["test_result"]["document"]["metadata"]["description"]
  end
end
