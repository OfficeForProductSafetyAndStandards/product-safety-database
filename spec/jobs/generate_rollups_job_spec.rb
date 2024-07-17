require "rails_helper"

class RollupRelation
  def joins(*_args)
    self
  end

  def rollup(*_args)
    true
  end
end

RSpec.describe GenerateRollupsJob, type: :job do
  before do
    allow(User).to receive(:rollup)
    allow(Investigation::Notification).to receive(:rollup)
    allow(Product).to receive(:rollup)
    allow(Ahoy::Visit).to receive(:rollup)
    allow(Ahoy::Event).to receive(:where).and_return(ahoy_event_relation)
    allow(ahoy_event_relation).to receive(:joins).and_return(ahoy_event_relation)
    allow(ahoy_event_relation).to receive(:rollup)
  end

  let(:ahoy_event_relation) { instance_double("RollupRelation") }

  describe "#perform - User rollups" do
    it "calls User rollup for New users (day)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("New users", interval: :day)
    end

    it "calls User rollup for New users (month)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("New users", interval: :month)
    end

    it "calls User rollup for New users (year)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("New users", interval: :year)
    end

    it "calls User rollup for Active users (day)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("Active users", column: :last_sign_in_at, interval: :day)
    end

    it "calls User rollup for Active users (month)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("Active users", column: :last_sign_in_at, interval: :month)
    end

    it "calls User rollup for Active users (year)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("Active users", column: :last_sign_in_at, interval: :year)
    end

    it "calls User rollup for Invited users (day)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("Invited users", column: :invited_at, interval: :day)
    end

    it "calls User rollup for Invited users (month)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("Invited users", column: :invited_at, interval: :month)
    end

    it "calls User rollup for Invited users (year)" do
      described_class.new.perform
      expect(User).to have_received(:rollup).with("Invited users", column: :invited_at, interval: :year)
    end
  end

  describe "#perform - Investigation::Notification rollups" do
    it "calls Investigation::Notification rollup for New notifications (day)" do
      described_class.new.perform
      expect(Investigation::Notification).to have_received(:rollup).with("New notifications", interval: :day)
    end

    it "calls Investigation::Notification rollup for New notifications (month)" do
      described_class.new.perform
      expect(Investigation::Notification).to have_received(:rollup).with("New notifications", interval: :month)
    end

    it "calls Investigation::Notification rollup for New notifications (year)" do
      described_class.new.perform
      expect(Investigation::Notification).to have_received(:rollup).with("New notifications", interval: :year)
    end
  end

  describe "#perform - Product rollups" do
    it "calls Product rollup for New products (day)" do
      described_class.new.perform
      expect(Product).to have_received(:rollup).with("New products", interval: :day)
    end

    it "calls Product rollup for New products (month)" do
      described_class.new.perform
      expect(Product).to have_received(:rollup).with("New products", interval: :month)
    end

    it "calls Product rollup for New products (year)" do
      described_class.new.perform
      expect(Product).to have_received(:rollup).with("New products", interval: :year)
    end
  end

  describe "#perform - Ahoy::Visit rollups" do
    it "calls Ahoy::Visit rollup for New visits (day)" do
      described_class.new.perform
      expect(Ahoy::Visit).to have_received(:rollup).with("New visits", column: :started_at, interval: :day)
    end

    it "calls Ahoy::Visit rollup for New visits (month)" do
      described_class.new.perform
      expect(Ahoy::Visit).to have_received(:rollup).with("New visits", column: :started_at, interval: :month)
    end

    it "calls Ahoy::Visit rollup for New visits (year)" do
      described_class.new.perform
      expect(Ahoy::Visit).to have_received(:rollup).with("New visits", column: :started_at, interval: :year)
    end
  end

  describe "#perform - ahoy_rollups for various events" do
    events = [
      "Visited help page",
      "Performed search",
      "Generated notification export",
      "Generated product export",
      "Generated business export",
      "Updated product",
      "Created notification from product",
      "Added product to existing notification",
      "Updated notification name",
      "Updated batch number",
      "Updated custom codes",
      "Updated number of affected units",
      "Updated overseas regulator",
      "Added test result",
      "Updated test result"
    ]

    events.each do |event|
      it "calls ahoy_rollups for #{event} (day)" do
        described_class.new.perform
        expect(ahoy_event_relation).to have_received(:rollup).with(event, column: :started_at, interval: :day)
      end

      it "calls ahoy_rollups for #{event} (month)" do
        described_class.new.perform
        expect(ahoy_event_relation).to have_received(:rollup).with(event, column: :started_at, interval: :month)
      end

      it "calls ahoy_rollups for #{event} (year)" do
        described_class.new.perform
        expect(ahoy_event_relation).to have_received(:rollup).with(event, column: :started_at, interval: :year)
      end
    end
  end
end
