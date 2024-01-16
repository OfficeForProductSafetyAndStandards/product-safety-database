RSpec.describe DeleteNotificationForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(notification:) }

  let(:notification) { create(:notification) }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no notification" do
      let(:notification) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with notification that has associated products" do
      let(:notification) { create(:notification, :with_products) }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
