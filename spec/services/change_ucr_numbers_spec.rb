require "rails_helper"

RSpec.describe ChangeUcrNumbers, :with_stubbed_opensearch, :with_test_queue_adapter do
  subject(:result) { described_class.call!(investigation_product:, ucr_numbers:, user:) }

  let(:investigation_product) { create(:investigation_product) }
  let(:ucr_numbers) do
    {
      "ucr_numbers_attributes" => {
        "0" => { "id" => "", "number" => "1234" }
      }
    }
  end
  let(:user) { create(:user, :activated) }

  context "with no investigation product parameter" do
    subject(:result) { described_class.call(user:, ucr_numbers:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    subject(:result) { described_class.call(investigation_product:, ucr_numbers:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  it "succeeds" do
    expect(result).to be_success
  end

  it "sets the UCR numbers on the investigation product" do
    expect { result }.to change { investigation_product.ucr_numbers.count }.from(0).to(1)
  end

  it "creates an audit activity" do
    expect { result }.to change(AuditActivity::Investigation::UpdateCaseSpecificProductInformation, :count).by(1)
  end

  it "sends an email" do
    expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated)
  end

  context "when we are adding multiple UCR numbers" do
    let(:ucr_numbers) do
      {
        "ucr_numbers_attributes" => {
          "0" => { "id" => "", "number" => "1234" },
          "1" => { "id" => "", "number" => "5678" }
        }
      }
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "sets the UCR numbers on the investigation product" do
      expect { result }.to change { investigation_product.ucr_numbers.count }.from(0).to(2)
    end

    it "creates an audit activity" do
      expect { result }.to change(AuditActivity::Investigation::UpdateCaseSpecificProductInformation, :count).by(1)
    end

    it "sends an email" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated)
    end
  end

  context "when we try to add a new blank UCR number" do
    let(:ucr_numbers) do
      {
        "ucr_numbers_attributes" => {
          "0" => { "id" => "", "number" => "" }
        }
      }
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "does not set the UCR numbers on the investigation product" do
      expect { result }.not_to(change { investigation_product.ucr_numbers.count })
    end
  end

  context "when one UCR number is already present" do
    let!(:ucr_number) { create(:ucr_number, investigation_product:, number: "1234") }

    let(:ucr_numbers) do
      {
        "ucr_numbers_attributes" => {
          "0" => { "id" => ucr_number.id, "number" => ucr_number.number },
          "1" => { "id" => "", "number" => "5678" }
        }
      }
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "sets the UCR numbers on the investigation product" do
      expect { result }.to change { investigation_product.ucr_numbers.count }.from(1).to(2)
    end

    it "creates an audit activity" do
      expect { result }.to change(AuditActivity::Investigation::UpdateCaseSpecificProductInformation, :count).by(1)
    end

    it "sends an email" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated)
    end
  end
end
