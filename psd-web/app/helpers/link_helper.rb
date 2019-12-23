module LinkHelper
  def link_with_hidden_text_to(text, hidden_text, url, html_options = {})
    link_to url, html_options do
      "#{text}<span class=\"govuk-visually-hidden\"> (#{hidden_text})</span>".html_safe
    end
  end
end
