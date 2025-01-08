RSpec.shared_examples "with a blank description" do |object, reader|
  describe "with a blank description" do
    before { public_send(object).description = "" }

    specify { expect(public_send(reader).description).to be_nil }
  end
end
