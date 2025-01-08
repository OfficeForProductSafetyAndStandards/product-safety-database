RSpec.shared_context "with product form helpers", shared_context: :metadata do
  def counterfeit_answer(authenticity)
    {
      "counterfeit" => "Yes",
      "genuine" => "No",
      "unsure" => "Unsure",
      "missing" => "Not provided"
    }[authenticity]
  end

  def when_placed_on_market_answer(when_placed_on_market)
    {
      "before_2021" => "Yes",
      "on_or_after_2021" => "No",
      "unknown_date" => "Unable to ascertain",
      "missing" => "Not provided"
    }[when_placed_on_market]
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with product form helpers", with_product_form_helper: true
end
