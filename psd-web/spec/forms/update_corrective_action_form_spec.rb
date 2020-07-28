require "rails_helper"

RSpec.describe UpdateCorrectiveActionForm do
  include_context "with corrective action setup for updates"

  subject(:update_corrective_action_form) { described_class.new(corrective_action_params) }

  let(:related_file) { "Yes" }
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
      related_file: related_file,
      file: {
        file: new_file,
        description: new_file_description
      }
    }
  end

  describe "#valid?" do
    context "with valid params" do
      it { is_expected.to be_valid }
    end

    context "when related_file is checked but not file is present" do
      before { corrective_action_params[:file][:file] = nil }

      it "prompts the user to select a file or choose no", :aggregate_failures do
        expect(update_corrective_action_form).to be_invalid
        expect(update_corrective_action_form.errors.full_messages_for(:base)).to eq(["Provide a related file or select no"])
      end
    end

    context "when the decided date is missing a component" do
      before { corrective_action_params[:date_decided_year] = "" }

      it "prompts the user to select a file or choose no", :aggregate_failures do
        expect(update_corrective_action_form).to be_invalid
        expect(update_corrective_action_form.errors.full_messages_for(:date_decided)).to eq(["Date decided must include a year"])
      end
    end

    context "when the decided date is in the future" do
      before { corrective_action_params[:date_decided_year] = Time.zone.today.year + 1 }

      it "prompts the user to select a file or choose no", :aggregate_failures do
        expect(update_corrective_action_form).to be_invalid
        expect(update_corrective_action_form.errors.full_messages_for(:date_decided)).to eq(["The date of corrective action decision can not be in the future"])
      end
    end
  end
end
