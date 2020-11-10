RSpec.shared_context "with product form helpers", shared_context: :metadata do
  def counterfeit_answer(authenticity)
    case authenticity
    when "counterfeit" then "Yes"
    when "genuine"     then "No"
    when "unsure"      then "Unsure"
    when "missing"     then "Not provided"
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with product form helpers", with_product_form_helper: true
end
