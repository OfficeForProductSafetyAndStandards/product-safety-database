require "rails_helper"

RSpec.describe UpdateCorrectiveActionForm do
  include_context "with corrective action setup for updates"

  subject(:update_corrective_action_form) { described_class.new(corrective_action_params) }

  let(:corrective_action_params) do
    {
      summary: new_summary,
      date_decided_day: new_date_decided.day,
      date_decided_month: new_date_decided.month,
      date_decided_year: new_date_decided.year,
      legislation: new_legislation,
      duration: new_duration,
      details: new_details,
      measure_type: new_measure_type,
      geographic_scope: new_geographic_scope,
      file: {
        file: new_file,
        description: new_file_description
      }
    }
  end

  describe "#valid?" do
    before do
      # byebug
    end


    context "with valid params" do
      it do
        update_corrective_action_form.valid?
        ap update_corrective_action_form.errors.full_messages
        is_expected.to be_valid

      end
    end
  end
end
