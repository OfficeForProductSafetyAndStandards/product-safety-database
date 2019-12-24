require "rails_helper"

RSpec.shared_examples "finds the relevant investigation" do
  before do
    investigation.reload.__elasticsearch__.index_document(refresh: :wait_for)
  end

  it "finds the relevant investigation" do
    expect(perform_search.records.to_a).to include(investigation)
  end
end

RSpec.describe ElasticsearchQuery, :with_elasticsearch, :with_keycloak_config do
  let(:user)           { create(:user) }
  let(:filter_params)  { {} }
  let(:sorting_params) { {} }

  subject { described_class.new(query, filter_params, sorting_params) }

  def perform_search
    Investigation.full_search(subject)
  end

  # TODO: these specs are a port of the deprecated (and flaky) Minitest tests.
  # Currently full_search returns pretty much every record so further work is
  # needed to improve the relevance of the results. We should then add
  # assertions that irrelevant records are *not* returned here.
  describe "#build_query" do
    let(:batch_number)      { SecureRandom.uuid }
    let(:country_of_origin) { "United Kingdom" }
    let(:product)           { create(:product, country_of_origin: country_of_origin, batch_number: batch_number) }
    let(:investigation)     { create(:allegation, assignable: user, products: [product]) }

    before do
      allow(NotifyMailer)
        .to receive(:investigation_updated)
        .and_return(double(NotifyMailer, deliver_later: nil))
    end

    context "when searching on an investigation's product" do
      context "search for product_code" do
        let(:query) { product.product_code }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for name" do
        let(:query) { product.name }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for batch_number" do
        let(:query) { product.batch_number }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for description" do
        let(:query) { product.description }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for country of origin" do
        let(:query) { product.country_of_origin }

        it "does not find the investigation" do
          expect(perform_search.records).to_not include(investigation)
        end
      end
    end

    context "when searching  on an investigation's correspondence" do
      let!(:correspondence) { create(:correspondence, investigation: investigation) }

      context "search for the overview" do
        let(:query) { correspondence.overview }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for the email address" do
        let(:query) { correspondence.email_address }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for the name" do
        let(:query) { correspondence.correspondent_name }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for the email_subject" do
        let(:query) { correspondence.email_subject }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for the details" do
        let(:query) { correspondence.details }

        it_behaves_like "finds the relevant investigation"
      end

      context "search for the phone_number" do
        let(:query) { correspondence.phone_number }

        it_behaves_like "finds the relevant investigation"
      end
    end

    context "when searching on the complainant fields" do
      let!(:complainant) { create(:complainant, investigation: investigation) }

      context "searching by complainant name" do
        let(:query) { complainant.name }

        it_behaves_like "finds the relevant investigation"
      end

      context "searching by complainant phone number" do
        let(:query) { complainant.phone_number }

        it_behaves_like "finds the relevant investigation"
      end

      context "searching by complainant email address" do
        let(:query) { complainant.email_address }

        it_behaves_like "finds the relevant investigation"
      end
    end

    context "when searcing on a business" do
      let!(:business) { create(:business, investigations: [investigation]) }

      context "searching by business trading name" do
        let(:query) { business.trading_name }

        it_behaves_like "finds the relevant investigation"
      end

      context "searching by business number" do
        let(:query) { business.company_number }


        it_behaves_like "finds the relevant investigation"
      end
    end
  end
end
