class SendSMS
  include Singleton

  TEMPLATES = {
    send_otp_code: "8b758d39-29ad-4f02-bb52-a68cfac007b6"
  }.freeze

  attr_reader :pool

  def initialize
    self.pool = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5), timeout: 1) do
      Notifications::Client.new(Rails.configuration.notify_api_key)
    end
  end

  def self.send_otp_code(mobile_number:, code:)
    instance.pool.with do |client|
      client.send_sms(
        phone_number: mobile_number,
        template_id: TEMPLATES[:send_otp_code],
        personalisation: { code: code }
      )
    end
  end

private

  attr_writer :pool
end
