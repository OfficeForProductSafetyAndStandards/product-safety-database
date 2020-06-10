class TestDecorator < ApplicationDecorator
  delegate_all
  include SupportingInformationHelper

  def title
    result_text = if result.passed?
                    "Passed test"
                  elsif result.failed?
                    "Failed test"
                  else
                    "Test result"
                  end

    "#{result_text}: #{product.name}"
  end

  def supporting_information_title
    title
  end

  def date_of_activity
    date.to_s(:govuk)
  end

  def date_added
    created_at.to_s(:govuk)
  end

  def result
    @result ||= ActiveSupport::StringInquirer.new(object.result || "")
  end

  def supporting_information_type
    "Test result"
  end
end
