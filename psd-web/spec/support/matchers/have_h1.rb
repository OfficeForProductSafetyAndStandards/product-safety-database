module PageMatchers
  def have_h1(text)
    have_selector("h1", text: text)
  end
end
