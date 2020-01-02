require "rails_helper"

# TODO: Refactor Investigation model to remove callback hell and dependency on User.current
RSpec.shared_examples "an Investigation" do
  describe "record creation", :with_stubbed_elasticsearch, :with_keycloak_config do
    let(:user) { create(:user) }
    let(:investigation) { build(factory) }

    before do
      User.current = user
      allow(NotifyMailer)
        .to receive(:investigation_created)
        .and_return(double("mailer", deliver_later: true))
      investigation.save # Need to trigger save after stubbing the mailer due to callback hell
    end

    after do
      User.current = nil # :puke:
    end

    it "sends a notification email" do
      expect(NotifyMailer).to have_received(:investigation_created).with(investigation.pretty_id, user.name, user.email, investigation.decorate.title, investigation.case_type)
    end
  end

  # TODO: these specs are a port of the deprecated (and flaky) Minitest tests.
  # Currently full_search returns pretty much every record so further work is
  # needed to improve the relevance of the results. We should then add
  # assertions that irrelevant records are *not* returned here.
  #
  describe ".full_search", :with_elasticsearch, :with_keycloak_config, :with_stubbed_mailer do
    let(:product) { create(:product_iphone) }
    let(:correspondence) { create(:correspondence) }
    let(:business) { create(:business) }

    let!(:investigation_with_product) { create(factory, products: [product]) }
    let!(:investigation_with_correspondence) { create(factory, correspondences: [correspondence]) }
    let!(:investigation_with_business) { create(factory, :with_business, business_to_add: business) }
    let!(:investigation_with_complainant) { create(factory) }
    let!(:complainant) { create(:complainant, investigation: investigation_with_complainant) }

    let(:query) { ElasticsearchQuery.new(query_string, {}, {}) }

    let(:search_results) { described_class.full_search(query).records.map(&:id) }

    # This is necessary because Elasticsearch does not appear to re-index automatically when some associated records are added post-create
    before do
      [investigation_with_business, investigation_with_complainant].each do |investigation|
        investigation.__elasticsearch__.index_document
      end
    end

    context "searching by product name" do
      let(:query_string) { product.name }

      it "returns investigations with a product matching the searched product name" do
        expect(search_results).to include(investigation_with_product.id)
      end
    end

    context "searching by product code" do
      let(:query_string) { product.product_code }

      it "returns investigations with a product matching the searched product code" do
        expect(search_results).to include(investigation_with_product.id)
      end
    end

    context "searching by product batch number" do
      let(:query_string) { product.batch_number }

      it "returns investigations with a product matching the searched product batch number" do
        expect(search_results).to include(investigation_with_product.id)
      end
    end

    context "searching by product description" do
      let(:query_string) { product.description }

      it "returns investigations with a product matching the searched product description" do
        expect(search_results).to include(investigation_with_product.id)
      end
    end

    context "searching by product country of origin" do
      let(:query_string) { product.country_of_origin }

      it "does not return investigations with a product matching the searched product country" do
        expect(search_results).not_to include(investigation_with_product.id)
      end
    end

    context "searching by correspondence overview" do
      let(:query_string) { correspondence.overview }

      it "returns investigations with correspondence matching the searched correspondence overview" do
        expect(search_results).to include(investigation_with_correspondence.id)
      end
    end

    context "searching by correspondence details" do
      let(:query_string) { correspondence.details }

      it "returns investigations with correspondence matching the searched correspondence details" do
        expect(search_results).to include(investigation_with_correspondence.id)
      end
    end

    context "searching by correspondent name" do
      let(:query_string) { correspondence.correspondent_name }

      it "returns investigations with correspondence matching the searched correspondent name" do
        expect(search_results).to include(investigation_with_correspondence.id)
      end
    end

    context "searching by correspondence email address" do
      let(:query_string) { correspondence.email_address }

      it "returns investigations with correspondence matching the searched correspondence email address" do
        expect(search_results).to include(investigation_with_correspondence.id)
      end
    end

    context "searching by correspondence email subject" do
      let(:query_string) { correspondence.email_subject }

      it "returns investigations with correspondence matching the searched correspondence email subject" do
        expect(search_results).to include(investigation_with_correspondence.id)
      end
    end

    context "searching by correspondence phone number" do
      let(:query_string) { correspondence.phone_number }

      it "returns investigations with correspondence matching the searched correspondence phone number" do
        expect(search_results).to include(investigation_with_correspondence.id)
      end
    end

    context "searching by complainant name" do
      let(:query_string) { complainant.name }

      it "returns investigations with the complainant matching the searched complainant name" do
        expect(search_results).to include(investigation_with_complainant.id)
      end
    end

    context "searching by complainant phone number" do
      let(:query_string) { complainant.phone_number }

      it "returns investigations with the complainant matching the searched complainant phone number" do
        expect(search_results).to include(investigation_with_complainant.id)
      end
    end

    context "searching by complainant email address" do
      let(:query_string) { complainant.email_address }

      it "returns investigations with the complainant matching the searched complainant email address" do
        expect(search_results).to include(investigation_with_complainant.id)
      end
    end

    context "searching by business trading name" do
      let(:query_string) { business.trading_name }

      it "returns investigations with a business matching the searched business trading name" do
        expect(search_results).to include(investigation_with_business.id)
      end
    end

    context "searching by business number" do
      let(:query_string) { business.company_number }

      it "returns investigations with a business matching the searched business number" do
        expect(search_results).to include(investigation_with_business.id)
      end
    end
  end
end

RSpec.describe Investigation::Allegation do
  let(:factory) { :allegation }
  it_behaves_like "an Investigation"
end

RSpec.describe Investigation::Enquiry do
  let(:factory) { :enquiry }
  it_behaves_like "an Investigation"
end

RSpec.describe Investigation::Project do
  let(:factory) { :project }
  it_behaves_like "an Investigation"
end
