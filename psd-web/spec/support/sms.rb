# frozen_string_literal: true

class TestOTPSMS
  attr_accessor :number, :code

  def initialize(number, code)
    @number = number
    @code = code
  end
end

RSpec.shared_context "with stubbed otp sms", shared_context: :metadata do
  let!(:delivered_sms) { [] }
  before do
    allow(SendSMS).to receive(:otp_code).and_wrap_original do |_m, *args|
      delivered_sms << TestOTPSMS.new(*args.first, *args.second)
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed otp sms", with_stubbed_otp_sms: true
end
