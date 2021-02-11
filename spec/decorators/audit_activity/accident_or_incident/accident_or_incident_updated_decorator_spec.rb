require "rails_helper"

RSpec.describe AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdatedDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:decorated_activity) { accident.reload.investigation.activities.find_by!(type: "AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated").decorate }

  let(:accident) { create(:accident, date: date, is_date_known: is_date_known, usage: usage, severity: severity, severity_other: severity_other, additional_info: additional_info) }
  let(:date) { Date.current }
  let(:is_date_known) { "yes" }
  let(:severity) { "high" }
  let(:severity_other) { nil }
  let(:usage) { "during_normal_use" }
  let(:product) { build(:product) }
  let(:additional_info) { "something extra" }
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) do
    create(:allegation,
           creator: user,
           products: [product])
  end

  let(:new_date)                              { Date.current - 1.year }
  let(:new_is_date_known)                     { "yes" }
  let(:new_usage)                             { "during_misuse" }
  let(:new_severity)                          { "serious" }
  let(:new_severity_other)                    { "dead serious" }

  let(:accident_or_incident_form)    { AccidentOrIncidentForm.from(accident) }
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
        .merge(accident_or_incident: accident, user: user, changes: changes, investigation: accident.investigation)
    )
  end

  it { expect(decorated_activity.new_date).to eq(new_date.to_s(:govuk)) }
  it { expect(decorated_activity.new_severity).to eq(I18n.t(".accident_or_incident.severity.#{new_severity}")) }
  it { expect(decorated_activity.new_usage).to eq(I18n.t(".accident_or_incident.usage.#{new_usage}")) }

  describe "#new_date" do
    context "when date changes from known to unknown" do
      let(:new_is_date_known) { "no" }
      let(:new_date) { nil }

      it "returns `unknown`" do
        expect(decorated_activity.new_date).to eq("Unknown")
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
  end
end
