class Test::Result < Test

  enum result: { passed: "Pass", failed: "Fail", other: "Other" }

  def pretty_name
    "test result"
  end

  def requested?
    false
  end
end
