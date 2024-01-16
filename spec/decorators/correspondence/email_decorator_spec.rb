RSpec.describe Correspondence::EmailDecorator do
  describe "#title" do
    context "when there is a overview" do
      let(:email) { build(:email, overview: "email with Bob") }

      it "returns the overview" do
        expect(email.decorate.title).to eq("email with Bob")
      end
    end

    context "when there is no overview" do
      let(:date) { Date.parse("2020-01-01") }
      let(:email) { build(:email, overview: "", correspondence_date: date) }

      it "uses the email date" do
        expect(email.decorate.title).to eq("Email on 1 January 2020")
      end
    end
  end
end
