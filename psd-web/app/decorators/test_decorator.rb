class TestDecorator < Draper::Decorator
  delegate_all
  include SupportingInformationHelper

  def title
    result_text = if passed?
                    "Passed test"
                  elsif failed?
                    "Failed test"
                  else
                    "Test result"
                  end

    "#{result_text}: #{product.name}"
  end

  def test

  end
end
