require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::AddDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:decorated_activity) do
    described_class.decorate(
      AuditActivity::CorrectiveAction::Add.new(
        business: business,
        metadata: AuditActivity::CorrectiveAction::Add.build_metadata(corrective_action)
      )
    )
  end

  let(:business)                      { create(:business) }
  let(:corrective_action)             { create(:corrective_action, business: business, has_online_recall_information: has_online_recall_information, online_recall_information: online_recall_information) }
  let(:online_recall_information)     { Faker::Internet.url(host: "example.com") }
  let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"] }

  describe "#legislation" do
    it "returns the legislation" do
      expect(decorated_activity.legislation).to eq(corrective_action.legislation)
    end
  end

  describe "#online_recall_information" do
    context "with online recall information" do
      specify do
        expect(decorated_activity.online_recall_information).to match(online_recall_information)
      end
    end

    context "with no online recall information" do
      let(:online_recall_information)     { nil }
      let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_no"] }

      specify do
        expect(decorated_activity.online_recall_information).to eq("Not published online")
      end
    end

    context "when online recall information is not relevant" do
      let(:online_recall_information)     { nil }
      let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_not_relevant"] }

      specify do
        expect(decorated_activity.online_recall_information).to eq("Not relevant")
      end
    end
  end

  describe "#decided_date" do
    specify { expect(decorated_activity.date_decided).to eq(corrective_action.date_decided.to_s(:govuk)) }
  end

  describe "#measure_type" do
    specify { expect(decorated_activity.measure_type).to eq(CorrectiveAction.human_attribute_name("measure_type.#{corrective_action.measure_type}")) }
  end

  describe "#duration" do
    specify { expect(decorated_activity.duration).to eq(CorrectiveAction.human_attribute_name("measure_type.#{corrective_action.duration}")) }
  end
end
