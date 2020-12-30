RSpec.shared_examples "it does not allow dates in the future" do |form_attribute, attribute|
  let(form_attribute) { { day: "1", month: "1", year: 1.year.from_now.to_date.year.to_s } }

  it "is not valid and contains an error message", :aggregate_failures do
    expect(form).not_to be_valid
    expect(form.errors.details[attribute || form_attribute]).to eq([{ error: :in_future }])
  end
end

RSpec.shared_examples "it does not allow malformed dates" do |form_attribute, attribute|
  let(form_attribute) { { day: "99", month: "1", year: "2000" } }

  it "is not valid and contains an error message", :aggregate_failures do
    expect(form).not_to be_valid
    expect(form.errors.details[attribute || form_attribute]).to eq([{ error: :must_be_real }])
  end
end

RSpec.shared_examples "it does not allow an incomplete" do |form_attribute, attribute|
  let(form_attribute) { { day: "1", month: "", year: "" } }

  it "is not valid and contains an error message", :aggregate_failures do
    expect(form).not_to be_valid
    expect(form.errors.details[attribute || form_attribute]).to eq([{ error: :incomplete, missing_date_parts: "month and year" }])
  end
end
