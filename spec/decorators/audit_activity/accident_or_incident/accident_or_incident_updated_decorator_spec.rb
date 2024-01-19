require "rails_helper"

RSpec.describe AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdatedDecorator, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:decorated_activity) { accident.reload.investigation.activities.find_by!(type: "AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated").decorate }

  let(:accident) { create(:accident, date:, is_date_known:, usage:, severity:, severity_other:, additional_info:) }
  let(:date) { Date.current }
  let(:is_date_known) { true }
  let(:severity) { "high" }
  let(:severity_other) { nil }
  let(:usage) { "during_normal_use" }
  let(:product) { build(:product) }
  let(:additional_info) { "something extra" }
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:notification) do
    create(:notification,
           creator: user,
           products: [product])
  end

  let(:new_date)                              { Date.current - 1.year }
  let(:new_is_date_known)                     { true }
  let(:new_usage)                             { "during_misuse" }
  let(:new_severity)                          { "serious" }
  let(:new_severity_other)                    { "dead serious" }

  let(:accident_or_incident_form) { AccidentOrIncidentForm.from(accident) }
  let(:accident_or_incident_attributes) do
    accident_or_incident_form.tap { |form|
      form.tap(&:valid?).assign_attributes(
        date: new_date,
        is_date_known: new_is_date_known,
        usage: new_usage,
        severity: new_severity,
        severity_other: new_severity_other
      )
    }.serializable_hash
  end
  let(:changes) { accident_or_incident_form.changes }

  before do
    UpdateAccidentOrIncident.call!(
      accident_or_incident_attributes
        .merge(accident_or_incident: accident, user:, changes:, notification: accident.investigation)
    )
  end

  it { expect(decorated_activity.new_date).to eq(new_date.to_formatted_s(:govuk)) }
  it { expect(decorated_activity.new_severity).to eq(I18n.t(".accident_or_incident.severity.#{new_severity}")) }
  it { expect(decorated_activity.new_usage).to eq(I18n.t(".accident_or_incident.usage.#{new_usage}")) }

  describe "#new_date" do
    context "when date changes from known to unknown" do
      let(:new_is_date_known) { false }
      let(:new_date) { nil }

      it "returns `unknown`" do
        expect(decorated_activity.new_date).to eq("Unknown")
      end
    end
  end

  describe "#date_changed?" do
    context "when date changes from known to unknown" do
      let(:date) { Date.current }
      let(:is_date_known) { true }
      let(:new_date) { nil }
      let(:new_is_date_known) { false }

      it "returns true" do
        expect(decorated_activity.date_changed?).to eq(true)
      end
    end

    context "when date changes from unknown to known" do
      let(:date) { nil }
      let(:is_date_known) { false }
      let(:new_date) { Date.current }
      let(:new_is_date_known) { true }

      it "returns true" do
        expect(decorated_activity.date_changed?).to eq(true)
      end
    end

    context "when date is unknown and unchanged" do
      let(:date) { nil }
      let(:is_date_known) { false }
      let(:new_date) { nil }
      let(:new_is_date_known) { false }

      it "returns false" do
        expect(decorated_activity.date_changed?).to eq(false)
      end
    end

    context "when date is known and unchanged" do
      let(:date) { Date.current }
      let(:is_date_known) { true }
      let(:new_date) { Date.current }
      let(:new_is_date_known) { true }

      it "returns false" do
        expect(decorated_activity.date_changed?).to eq(false)
      end
    end
  end

  describe "#new_severity" do
    context "when severity changes to other" do
      let(:new_severity) { "other" }
      let(:new_severity_other) { "deadly" }

      it "returns `new_severity_other`" do
        expect(decorated_activity.new_severity).to eq(new_severity_other)
      end
    end

    context "when severity stays at other but severity_other changes" do
      let(:severity) { "other" }
      let(:severity_other) { "not deadly" }
      let(:new_severity) { "other" }
      let(:new_severity_other) { "deadly" }

      it "returns `new_severity_other`" do
        expect(decorated_activity.new_severity).to eq(new_severity_other)
      end
    end

    context "when severity changes from other to specified severity" do
      let(:severity) { "other" }
      let(:severity_other) { "not deadly" }
      let(:new_severity) { "high" }

      it "returns `new_severity`" do
        expect(decorated_activity.new_severity).to eq(new_severity.capitalize)
      end
    end

    describe "#severity_changed?" do
      context "when severity changes from other to specific" do
        let(:severity) { "other" }
        let(:new_severity) { "high" }

        it "returns true" do
          expect(decorated_activity.severity_changed?).to eq(true)
        end
      end

      context "when severity changes from one specified severity to another" do
        let(:severity) { "serious" }
        let(:new_severity) { "high" }

        it "returns true" do
          expect(decorated_activity.severity_changed?).to eq(true)
        end
      end

      context "when severity stays `other` and severity_other does not change" do
        let(:severity) { "other" }
        let(:severity_other) { "very" }
        let(:new_severity) { "other" }
        let(:new_severity_other) { "very" }

        it "returns false" do
          expect(decorated_activity.severity_changed?).to eq(false)
        end
      end

      context "when severity stays other but severity other changes" do
        let(:severity) { "other" }
        let(:severity_other) { "very" }
        let(:new_severity) { "other" }
        let(:new_severity_other) { "extreme" }

        it "returns true" do
          expect(decorated_activity.severity_changed?).to eq(true)
        end
      end
    end
  end
end
