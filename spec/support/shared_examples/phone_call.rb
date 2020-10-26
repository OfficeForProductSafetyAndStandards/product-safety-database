RSpec.shared_examples "with removed field" do |attribute, let_variable|
  context "when no value was present before" do
    let(:"#{let_variable || attribute}") { "" }
    let(:"new_#{let_variable || attribute}") { "" }

    it "returns an empty string" do
      expect(decorator.public_send("new_#{attribute}")).to be_empty
    end
  end

  context "when removing value" do
    let(:"new_#{let_variable || attribute}") { "" }

    it "shows the value has removed" do
      expect(decorator.public_send("new_#{attribute}")).to be_removed
    end
  end
end
