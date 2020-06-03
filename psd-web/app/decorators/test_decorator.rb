class TestDecorator < Draper::Decorator
  delegate_all

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
end
