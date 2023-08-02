require "rails_helper"

RSpec.describe AuditActivity::AccidentOrIncident::AccidentOrIncidentAddedDecorator, :with_stubbed_mailer, :with_stubbed_antivirus do
  let(:decorated_accident) do
    described_class.decorate(
      AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded.new(
        metadata: AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded.build_metadata(accident)
      )
    )
  end

  let(:accident) { create(:accident, date:, is_date_known:, usage:, severity:, severity_other:, additional_info:) }
  let(:date) { nil }
  let(:is_date_known) { "no" }
  let(:severity) { "serious" }
  let(:severity_other) { nil }
  let(:usage) { "during_normal_use" }
  let(:product) { build(:product) }
  let(:additional_info) { "something extra" }

  describe "#date" do
    context "when date is known" do
      let(:is_date_known) { "yes" }
      let(:date) { Date.current }

      it "returns formatted date" do
        expect(decorated_accident.date).to eq date.to_formatted_s(:govuk)
      end
    end

    context "when date is unknown" do
      let(:is_date_known) { "no" }

      it "returns unknown" do
        expect(decorated_accident.date).to eq "Unknown"
      end
    end
  end

  describe "#severity" do
    context "when severity is `other`" do
      let(:severity) { "other" }
      let(:severity_other) { "not very serious" }

      it "returns severity_other" do
        expect(decorated_accident.severity).to eq severity_other
      end
    end

    context "when severity is not `other`" do
      it "returns severity" do
        expect(decorated_accident.severity).to eq "Serious"
      end
    end
  end

  describe "#usage" do
    it "returns human friendly usage" do
      expect(decorated_accident.usage).to eq "Normal use"
    end
  end

  describe "#additional_info" do
    it "returns additional_info" do
      expect(decorated_accident.additional_info).to eq additional_info
    end
  end
end
