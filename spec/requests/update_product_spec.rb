require "rails_helper"

RSpec.describe "Updating a product", type: :request, with_stubbed_mailer: true, with_stubbed_elasticsearch: true do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user)    { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user) }
  let(:product)       { create(:product, investigations: [investigation], has_markings: "markings_no") }

  context "when user has permission to edit product" do
    before do
      sign_in(user)
      allow(UpdateProduct).to receive(:call!).and_return(true)
    end

    it "allows user to edit product" do
      put product_path(product),
          params: {
            product: {
              name: "something else"
            }
          }

      expect(UpdateProduct).to have_received(:call!)
    end
  end

  context "when user does not have permission to edit product" do
    before { sign_in(other_user) }

    it "raises an unauthorised error" do
      expect {
        put product_path(product),
            params: {
              product: { name: "something else" }
            }
      }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
