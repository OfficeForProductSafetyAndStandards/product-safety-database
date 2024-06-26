RSpec.shared_examples "it does not allow dates in the future" do |form_attribute, attribute|
  let(form_attribute) { Date.new(2028, 1, 1) }

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

RSpec.shared_examples "it does not allow far away dates" do |form_attribute, attribute, on_or_after: true, on_or_before: true|
  if on_or_before
    context "with a date 60 years from now" do
      let(form_attribute) { Date.new(60.years.from_now.year, 1, 1) }

      it "is not valid and contains an error message", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.details[attribute || form_attribute]).to eq([{ error: :recent_date }])
      end
    end
  end

  if on_or_after
    context "with a date before 1970" do
      let(form_attribute) { Date.new(1969, 1, 1) }

      it "is not valid and contains an error message", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.details[attribute || form_attribute]).to eq([{ error: :recent_date }])
      end
    end
  end
end
