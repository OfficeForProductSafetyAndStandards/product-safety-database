RSpec.shared_examples "with removed field" do |attribute, let_variable|
  context "when removing value" do
    let(let_variable || attribute) { "" }

    it "shows the value has removed" do
      expect(decorator.public_send(attribute)).to eq("Removed")
    end
  end
end
