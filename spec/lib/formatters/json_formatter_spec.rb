require "rails_helper"

RSpec.describe Formatters::JsonFormatter do
  let(:formatter) { described_class.new }
  let(:severity) { "INFO" }
  let(:time) { Time.zone.now }
  let(:progname) { "test" }
  let(:message) { '{"key":"value"}' }

  describe "#call" do
    it "outputs the message without Rails logger prefix" do
      formatted_output = formatter.call(severity, time, progname, message)
      expect(formatted_output).to eq("#{message}\n")
    end

    it "removes request ID prefix from the message" do
      message_with_prefix = "[9fab6652-fc16-445e-ae55-14d8a9fea00c] #{message}"
      formatted_output = formatter.call(severity, time, progname, message_with_prefix)
      expect(formatted_output).to eq("#{message}\n")
    end

    it "does not include severity in the output" do
      formatted_output = formatter.call(severity, time, progname, message)
      expect(formatted_output).not_to include(severity)
    end

    it "does not include time in the output" do
      formatted_output = formatter.call(severity, time, progname, message)
      expect(formatted_output).not_to include(time.to_s)
    end

    it "does not include progname in the output" do
      formatted_output = formatter.call(severity, time, progname, message)
      expect(formatted_output).not_to include(progname)
    end
  end
end
