require "rails_helper"

RSpec.describe Investigation do

  describe "setting reported_reason from separate boolean attributes" do

    let(:investigation) { Investigation.new }

    context "when setting only unsafe to true" do
      before do
        investigation.reported_reason_unsafe = true
        investigation.reported_reason_non_compliant = false
        investigation.reported_reason_safe_and_compliant = false
      end

      it "sets the reported_reason to `unsafe`" do
        expect(investigation.reported_reason).to eql(:unsafe)
      end
    end

    context "when setting only non_compliant to true" do
      before do
        investigation.reported_reason_unsafe = false
        investigation.reported_reason_non_compliant = true
        investigation.reported_reason_safe_and_compliant = false
      end

      it "sets the reported_reason to `non_compliant`" do
        expect(investigation.reported_reason).to eql(:non_compliant)
      end
    end

    context "when setting only safe_and_compliant to true" do
      before do
        investigation.reported_reason_unsafe = false
        investigation.reported_reason_non_compliant = false
        investigation.reported_reason_safe_and_compliant = true
      end

      it "sets the reported_reason to `safe_and_compliant`" do
        expect(investigation.reported_reason).to eql(:safe_and_compliant)
      end
    end

    context "when not setting any reported_reason properties to true" do
      before do
        investigation.reported_reason_unsafe = false
        investigation.reported_reason_non_compliant = false
        investigation.reported_reason_safe_and_compliant = false
      end

      it "sets the reported_reason to `nil`" do
        expect(investigation.reported_reason).to be_nil
      end
    end

  end

end
