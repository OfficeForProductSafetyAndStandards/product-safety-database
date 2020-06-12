module ContentHelper
  # Returns the content with all html escaped and line breaks
  # formatted using <p> and <br> tags. (Unlike `simple_format`,
  # which strips html tags except for a list of 'safe' tags)
  def format_with_line_breaks(content)
    simple_format(h(content), {}, sanitize: false)
  end
end
