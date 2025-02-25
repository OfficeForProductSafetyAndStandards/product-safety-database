require "rails_helper"

RSpec.describe "businesses/locations/_address_form", type: :view do
  let(:location) { Location.new }
  let(:form) { GOVUKDesignSystemFormBuilder::FormBuilder.new(:location, location, view, {}) }
  let(:optional_text) { " (Optional)" }

  before do
    without_partial_double_verification do
      allow(view).to receive_messages(all_countries_with_uk_first: [["United Kingdom", "GB"]], id_name: "location-country-field")
      allow(view).to receive(:t).with(".legend.hint").and_return("Some hint text")
    end

    render partial: "businesses/locations/address_form", locals: { form: form }
  end

  {
    address_line_1: "Building and street",
    city: "Town or city",
    county: "County",
    postal_code: "Postcode"
  }.each do |field, label_text|
    context "when checking #{field} field" do
      it "includes optional text in label" do
        expect(rendered).to have_field("location[#{field}]", type: "text")
        expect(rendered).to have_css("label", text: /#{Regexp.escape(label_text)}.*#{Regexp.escape(optional_text)}/)
      end
    end
  end

  describe "country field" do
    it "renders with correct label" do
      expect(rendered).to have_field("location[country]")
      expect(rendered).to have_css("label", text: "Country")
    end

    it "does not include optional text" do
      expect(rendered).not_to have_css("label", text: /Country#{Regexp.escape(optional_text)}/)
    end
  end
end
