class Test::Result < Test
  enum result: { passed: "Pass", failed: "Fail", other: "Other" }
  self.ignored_columns = %w[product_id]

  def pretty_name
    "test result"
  end

  def requested?
    false
  end
end
