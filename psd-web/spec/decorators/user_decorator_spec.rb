require "rails_helper"

RSpec.describe UserDecorator do
  let(:user) { build(:user) }

  subject { user.decorate }

  describe "#assignee_short_name" do
    let(:viewing_user) { build(:user, organisation: organisation) }

    context "when viewing from a user within the same organisation" do
      let(:organisation) { user.organisation }

      it { expect(subject.assignee_short_name(viewing_user: viewing_user)).to eq(user.name) }
    end

    context "when viewing from a user within another organisation" do
      let(:organisation) { build(:organisation) }

      it { expect(subject.assignee_short_name(viewing_user: viewing_user)).to eq(user.organisation.name) }
    end
  end

  describe "#error_summary" do
    let(:error_summary) { Capybara.string(subject.error_summary) }

    before do
      user.errors.add(:email, "Oopsy!")
      user.errors.add(:email, "Ding...")
      user.errors.add(:password, "WeakPassword")
    end

    it "has a list element with a link to the relevant field with error" do
      expect(error_summary).to have_css(".govuk-error-summary .govuk-error-summary__body ul li a[href='#email']", text: "Oopsy!")
      expect(error_summary).to have_css(".govuk-error-summary .govuk-error-summary__body ul li a[href='#email']", text: "Ding...")
      expect(error_summary).to have_css(".govuk-error-summary .govuk-error-summary__body ul li a[href='#password']", text: "WeakPassword")
    end
  end
end
