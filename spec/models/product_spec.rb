RSpec.describe Product do
  describe "#psd_ref", :with_stubbed_opensearch do
    let(:id) { 123 }
    let(:product) { create :product, :with_versions, id: }

    it "returns a reference formed with 'psd-' and the product's ID" do
      expect(product.psd_ref).to eq("psd-#{id}")
    end

    context "with timestamp" do
      let(:creation_time) { 1.day.ago }
      let(:timestamp) { creation_time.to_i }

      before do
        travel_to(creation_time) { product }
      end

      context "when case has been closed" do
        it "appends the timestamp" do
          expect(product.paper_trail.previous_version.psd_ref(timestamp:, investigation_was_closed: true)).to eq("psd-#{id}_#{timestamp}")
        end
      end

      context "when case has not been closed" do
        context "with a current instance" do
          it "does not append the timestamp" do
            expect(product.psd_ref(timestamp:)).to eq("psd-#{id}")
          end
        end

        context "with a versioned instance" do
          it "appends the timestamp" do
            expect(product.paper_trail.previous_version.psd_ref(timestamp:)).to eq("psd-#{id}_#{timestamp}")
          end
        end
      end
    end
  end

  describe "#owning_team" do
    let(:product) { build :product }

    it "returns nil for a new product" do
      expect(product.owning_team).to eq(nil)
    end
  end

  describe "#unique_investigation_products", :with_stubbed_mailer do
    let(:investigation) { create(:allegation) }
    let(:investigation_2) { create(:allegation) }
    let(:product) { create(:product) }

    context "when a product has multiple investigation_products that share the same investigation_product" do
      before do
        create(:investigation_product, investigation_id: investigation.id, product_id: product.id, investigation_closed_at: Time.current)
        create(:investigation_product, investigation_id: investigation.id, product_id: product.id, investigation_closed_at: Time.current)
        create(:investigation_product, investigation_id: investigation.id, product_id: product.id, investigation_closed_at: nil)
        create(:investigation_product, investigation_id: investigation_2.id, product_id: product.id, investigation_closed_at: nil)
      end

      it "returns only one investigation_product per investigation" do
        expect(product.unique_investigation_products.map(&:investigation_id)).to eq [investigation.id, investigation_2.id]
      end
    end
  end

  describe "#stale?", :with_stubbed_notify, :with_stubbed_mailer do
    context "when the product is less than 18 months old" do
      let(:product) { build :product, created_at: 1.day.ago }

      it "returns false" do
        expect(product.stale?).to be(false)
      end
    end

    context "when the product has an open case" do
      let(:investigation) { create :allegation, :with_products }
      let(:product) { investigation.products.first }

      it "returns false" do
        expect(product.stale?).to be(false)
      end
    end

    context "when the product has an closed case within 18 months" do
      let(:investigation) { create :allegation, :with_products, :closed, date_closed: 3.months.ago }
      let(:product) { investigation.products.first }

      it "returns false" do
        expect(product.stale?).to be(false)
      end
    end

    context "when the product had a notification unlinked within the last 18 months" do
      let(:notification) { create :notification, created_at: 2.years.ago }
      let(:product) { create :product }
      let(:user) { create :user }

      before do
        travel(-6.months) do
          AddProductToCase.call!(user:, investigation: notification, product:)
          RemoveProductFromNotification.call!(user:, investigation_product: product.investigation_products.find_by(investigation: notification), notification:)
        end
      end

      it "returns false" do
        expect(product.stale?).to be(false)
      end
    end

    context "when the product had a notification unlinked outside the last 18 months" do
      let(:notification) { create :notification, created_at: 2.years.ago }
      let(:product) { create :product }
      let(:user) { create :user }

      before do
        travel(-20.months) do
          AddProductToCase.call!(user:, investigation: notification, product:)
          RemoveProductFromNotification.call!(user:, investigation_product: product.investigation_products.find_by(investigation: notification), notification:)
        end
      end

      it "returns true" do
        expect(product.stale?).to be(true)
      end
    end
  end

  describe ".retire_stale_products!", :with_stubbed_notify, :with_stubbed_mailer do
    let!(:young_product) { create :product, created_at: 1.day.ago }
    let(:open_notification) { create :notification, :with_products }
    let!(:product_with_open_notification) { open_notification.products.first }
    let(:newly_closed_notification) { create :notification, :with_products, :closed, date_closed: 3.months.ago }
    let!(:product_with_newly_closed_notification) { newly_closed_notification.products.first }
    let(:older_notification_1) { create :notification, created_at: 2.years.ago }
    let(:older_notification_2) { create :notification, created_at: 3.years.ago }
    let(:product_unlinked_recently) { create :product }
    let(:product_unlinked_in_the_past) { create :product }
    let!(:old_product_never_linked) { create :product, created_at: (18.months + 1.day).ago }
    let(:user) { create :user }

    before do
      travel(-6.months) do
        AddProductToCase.call! user:, investigation: older_notification_1, product: product_unlinked_recently
        RemoveProductFromNotification.call!(user:, investigation_product: product_unlinked_recently.investigation_products.find_by(investigation: older_notification_1), notification: older_notification_1)
      end

      travel(-19.months) do
        AddProductToCase.call! user:, investigation: older_notification_1, product: product_unlinked_in_the_past
        RemoveProductFromNotification.call!(user:, investigation_product: product_unlinked_in_the_past.investigation_products.find_by(investigation: older_notification_1), notification: older_notification_1)
      end

      travel(-20.months) do
        AddProductToCase.call! user:, investigation: older_notification_2, product: product_unlinked_in_the_past
        RemoveProductFromNotification.call!(user:, investigation_product: product_unlinked_in_the_past.investigation_products.find_by(investigation: older_notification_2), notification: older_notification_2)
      end
    end

    it "retires any stale products", :aggregate_failures do
      described_class.retire_stale_products!

      expect(young_product.reload.retired_at).to be(nil)
      expect(product_with_open_notification.reload.retired_at).to be(nil)
      expect(product_with_newly_closed_notification.reload.retired_at).to be(nil)
      expect(product_unlinked_recently.reload.retired_at).to be(nil)

      expect(product_unlinked_in_the_past.reload.retired_at).not_to be(nil)
      expect(old_product_never_linked.reload.retired_at).not_to be(nil)
    end
  end
end
