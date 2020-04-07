# TODO: Refactor Investigation model to remove callback hell and dependency on User.current
RSpec.shared_examples "an Investigation" do
  let(:investigation) { build(factory) }

  describe "record creation", :with_stubbed_elasticsearch do
    let(:user) { create(:user) }

    before do
      User.current = user
      allow(NotifyMailer)
        .to receive(:investigation_created)
        .and_return(instance_double("ActionMailer::MessageDelivery", deliver_later: true))
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
