require "rails_helper"

RSpec.describe GenerateRollupsJob, type: :job do
  before do
    allow(User).to receive(:rollup)
    allow(Investigation::Notification).to receive(:rollup)
    allow(Product).to receive(:rollup)
    allow(Ahoy::Visit).to receive(:rollup)

    event_query = instance_double(ActiveRecord::Relation)
    allow(Ahoy::Event).to receive(:where).and_return(event_query)

    # If `joins` leads to a different object, create that double
    joins_result = instance_double(AnotherClassWithRollup) # Use the correct class
    allow(event_query).to receive(:joins).and_return(joins_result)

    # Ensure `rollup` is expected on the correct object
    allow(joins_result).to receive(:rollup).and_return(nil)

    described_class.new.perform
  end

  describe "User rollups", skip: "Will be removed when we move to Google Analytics" do
    describe "New users" do
      it "rolls up daily" do
        expect(User).to have_received(:rollup).with("New users", interval: :day)
      end

      it "rolls up monthly" do
        expect(User).to have_received(:rollup).with("New users", interval: :month)
      end

      it "rolls up yearly" do
        expect(User).to have_received(:rollup).with("New users", interval: :year)
      end
    end

    describe "Active users" do
      it "rolls up daily" do
        expect(User).to have_received(:rollup).with("Active users", column: :last_sign_in_at, interval: :day)
      end

      it "rolls up monthly" do
        expect(User).to have_received(:rollup).with("Active users", column: :last_sign_in_at, interval: :month)
      end

      it "rolls up yearly" do
        expect(User).to have_received(:rollup).with("Active users", column: :last_sign_in_at, interval: :year)
      end
    end

    describe "Invited users" do
      it "rolls up daily" do
        expect(User).to have_received(:rollup).with("Invited users", column: :invited_at, interval: :day)
      end

      it "rolls up monthly" do
        expect(User).to have_received(:rollup).with("Invited users", column: :invited_at, interval: :month)
      end

      it "rolls up yearly" do
        expect(User).to have_received(:rollup).with("Invited users", column: :invited_at, interval: :year)
      end
    end
  end

  describe "Notification rollups", skip: "Will be removed when we move to Google Analytics" do
    describe "New notifications" do
      it "rolls up daily" do
        expect(Investigation::Notification).to have_received(:rollup).with("New notifications", interval: :day)
      end

      it "rolls up monthly" do
        expect(Investigation::Notification).to have_received(:rollup).with("New notifications", interval: :month)
      end

      it "rolls up yearly" do
        expect(Investigation::Notification).to have_received(:rollup).with("New notifications", interval: :year)
      end
    end
  end

  describe "Product rollups", skip: "Will be removed when we move to Google Analytics" do
    it "rolls up daily" do
      expect(Product).to have_received(:rollup).with("New products", interval: :day)
    end

    it "rolls up monthly" do
      expect(Product).to have_received(:rollup).with("New products", interval: :month)
    end

    it "rolls up yearly" do
      expect(Product).to have_received(:rollup).with("New products", interval: :year)
    end
  end

  describe "Ahoy visit rollups", skip: "Will be removed when we move to Google Analytics" do
    it "rolls up daily" do
      expect(Ahoy::Visit).to have_received(:rollup).with("New visits", column: :started_at, interval: :day)
    end

    it "rolls up monthly" do
      expect(Ahoy::Visit).to have_received(:rollup).with("New visits", column: :started_at, interval: :month)
    end

    it "rolls up yearly" do
      expect(Ahoy::Visit).to have_received(:rollup).with("New visits", column: :started_at, interval: :year)
    end
  end
end
