module NotifyHelper
  def inset_text_for_notify(text)
    text.each_line.collect { |line| "^ #{line}" }.join
  end
end
