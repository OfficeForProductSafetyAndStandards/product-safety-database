require "rails_helper"

# TODO: Refactor Investigation model to remove callback hell and dependency on User.current
RSpec.shared_examples "an Investigation" do
  describe "record creation", :with_stubbed_elasticsearch do
    let(:user) { create(:user) }
    let(:investigation) { build(factory) }

    before do
      User.current = user
      allow(NotifyMailer)
        .to receive(:investigation_created)
        .and_return(double("mailer", deliver_later: true))
      investigation.save # Need to trigger save after stubbing the mailer due to callback hell
    end

    after do
      User.current = nil # :puke:
    end

    it "sends a notification email" do
      expect(NotifyMailer).to have_received(:investigation_created).with(investigation.pretty_id, user.name, user.email, investigation.decorate.title, investigation.case_type)
    end
  end
end

RSpec.describe Investigation::Allegation do
  let(:factory) { :allegation }
  it_behaves_like "an Investigation"
end

RSpec.describe Investigation::Enquiry do
  let(:factory) { :enquiry }
  it_behaves_like "an Investigation"
end

RSpec.describe Investigation::Project do
  let(:factory) { :project }
  it_behaves_like "an Investigation"
end
