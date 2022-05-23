module LinkHelper
  def link_with_hidden_text_to(text, hidden_text, url, html_options = {})
    link_to url, html_options do
      render "link_helper/link_with_hidden_text_to", text:, hidden_text:
    end
  end
end
