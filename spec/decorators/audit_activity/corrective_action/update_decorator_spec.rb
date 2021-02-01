require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::UpdateDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with corrective action setup for updates"

  subject(:decorated_activity) { corrective_action.reload.investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Update").decorate }

  let(:new_file_description) { "new corrective action file description" }
  let(:new_filename)         { "corrective_action.txt" }

  before do
    UpdateCorrectiveAction.call!(
      corrective_action: corrective_action,
      user: user,
      corrective_action_params: ActionController::Parameters.new(
        action: new_summary,
        date_decided_day: new_date_decided.day,
        date_decided_month: new_date_decided.month,
        date_decided_year: new_date_decided.year,
        legislation: new_legislation,
        duration: new_duration,
        details: new_details,
        measure_type: new_measure_type,
        geographic_scopes: new_geographic_scopes,
        file: {
          file: fixture_file_upload(new_filename),
          description: new_file_description
        }
      ).permit!
    )
  end

  it { expect(decorated_activity.new_action).to eq(CorrectiveAction.actions[new_summary]) }
  it { expect(decorated_activity.new_date_decided).to eq(new_date_decided.to_s(:govuk)) }
  it { expect(decorated_activity.new_legislation).to eq(new_legislation) }
  it { expect(decorated_activity.new_duration).to eq(new_duration) }
  it { expect(decorated_activity.new_details).to eq(new_details) }
  it { expect(decorated_activity.new_measure_type).to eq(new_measure_type) }
  it { expect(decorated_activity.new_geographic_scopes).to eq(new_geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }) }
  it { expect(decorated_activity.new_filename).to eq(File.basename(new_filename)) }
  it { expect(decorated_activity.new_file_description).to eq(new_file_description) }
end
