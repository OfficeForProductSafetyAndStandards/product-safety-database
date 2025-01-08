# Recording of test requests is deprecated - existing data is still supported
class Test::Request < Test
  def pretty_name
    "testing request"
  end

  def requested?
    true
  end
end
