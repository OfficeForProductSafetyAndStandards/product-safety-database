RSpec.describe Correspondence::MeetingDecorator do
  describe "#title" do
    context "when there is a overview" do
      let(:meeting) { build(:meeting, overview: "E-mail from Bob") }

      it "returns the overview" do
        expect(meeting.decorate.title).to eq("E-mail from Bob")
      end
    end

    context "when there is no overview" do
      let(:date) { Date.parse("2020-01-01") }
      let(:meeting) { build(:meeting, overview: "", correspondence_date: date) }

      it "uses the email date" do
        expect(meeting.decorate.title).to eq("Meeting on 1 January 2020")
      end
    end
  end
end
