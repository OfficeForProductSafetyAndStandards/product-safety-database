RSpec.describe Correspondence::PhoneCallDecorator do
  describe "#title" do
    context "when there is a overview" do
      let(:phone_call) { build(:correspondence_phone_call, overview: "Call with Bob") }

      it "returns the overview" do
        expect(phone_call.decorate.title).to eq("Call with Bob")
      end
    end

    context "when there is no overview" do
      let(:date) { Date.parse("2020-01-01") }
      let(:phone_call) { build(:correspondence_phone_call, overview: "", correspondence_date: date) }

      it "uses the phone call date" do
        expect(phone_call.decorate.title).to eq("Phone call on 1 January 2020")
      end
    end
  end
end
