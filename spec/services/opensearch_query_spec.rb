require "rails_helper"

RSpec.shared_examples "finds the relevant investigation" do
  before do
    investigation.reload.__elasticsearch__.index_document(refresh: :wait_for)
  end

  it "finds the relevant investigation" do
    expect(perform_search.records.to_a).to include(investigation)
  end
end

RSpec.describe OpensearchQuery, :with_opensearch, :with_stubbed_mailer do
  subject(:os_query) { described_class.new(query, filter_params, sorting_params) }

  let(:user)           { create(:user) }
  let(:filter_params)  { {} }
  let(:sorting_params) { {} }

  def perform_search
    Investigation.not_deleted.full_search(os_query)
  end

  # TODO: these specs are a port of the deprecated (and flaky) Minitest tests.
  # Currently full_search returns pretty much every record so further work is
  # needed to improve the relevance of the results. We should then add
  # assertions that irrelevant records are *not* returned here.
  describe "#build_query" do
    let(:country_of_origin)       { "United Kingdom" }
    let(:product)                 { create(:product, country_of_origin:) }
    let(:investigation)           { create(:allegation, creator: user, products: [product]) }

    before do
      allow(NotifyMailer)
        .to receive(:investigation_updated)
        .and_return(instance_double("ActionMailer::MessageDelivery", deliver_later: nil))
    end

    context "when searching on an investigation's product" do
      context "when searching for product_code" do
        let(:query) { product.product_code }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for name" do
        let(:query) { product.name }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for description" do
        let(:query) { product.description }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for country of origin" do
        let(:query) { product.country_of_origin }

        it "does not find the investigation" do
          expect(perform_search.records).not_to include(investigation)
        end
      end
    end

    context "when searching on an investigation's correspondence" do
      let!(:correspondence) { create(:email, investigation:) }

      context "when searching for the overview" do
        let(:query) { correspondence.overview }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for the email address" do
        let(:query) { correspondence.email_address }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for the name" do
        let(:query) { correspondence.correspondent_name }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for the email_subject" do
        let(:query) { correspondence.email_subject }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for the details" do
        let(:query) { correspondence.details }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching for the phone_number" do
        let(:query) { correspondence.phone_number }

        it_behaves_like "finds the relevant investigation"
      end
    end

    context "when searcing on a business" do
      let!(:business) { create(:business, investigations: [investigation]) }

      context "when searching by business trading name" do
        let(:query) { business.trading_name }

        it_behaves_like "finds the relevant investigation"
      end

      context "when searching by business number" do
        let(:query) { business.company_number }

        it_behaves_like "finds the relevant investigation"
      end
    end

    context "with a multi term search" do
      let!(:investigation_one)   { create(:allegation, description: "multi terms search") }
      let!(:investigation_two)   { create(:allegation, description: "multi terms") }
      let!(:investigation_three) { create(:allegation,  description: "term search") }
      let!(:investigation_four)  { create(:allegation,  description: "multi search") }

      let(:query) { "multi terms" }

      before do
        investigation_one.reload.__elasticsearch__.index_document(refresh: :wait_for)
        investigation_two.reload.__elasticsearch__.index_document(refresh: :wait_for)
        investigation_three.reload.__elasticsearch__.index_document(refresh: :wait_for)
        investigation_four.reload.__elasticsearch__.index_document(refresh: :wait_for)
      end

      it "finds the relevant investigations", :aggregate_failures do
        expect(perform_search.records.to_a)
          .to include(
            investigation_one,
            investigation_two
          )
      end
    end
  end
end
