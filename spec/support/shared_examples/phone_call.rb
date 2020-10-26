RSpec.shared_examples "with removed field" do |attribute, let_variable|
  context "when no value was present before" do
    let(:"#{let_variable || attribute}") { "" }
    let(:"new_#{let_variable || attribute}") { "" }

    it "returns an empty string" do
      expect(decorator.public_send("new_#{attribute}")).to eq(nil)
    end
  end

  context "when removing value" do
    let(:"new_#{let_variable || attribute}") { "" }

    it "shows the value has removed" do
      expect(decorator.public_send("new_#{attribute}")).to eq("Removed")
    end
  end
end
