class SendSMS
  include Singleton

  TEMPLATES = {
    otp_code: "091c8861-8532-4907-abc0-f89632c34f09"
  }.freeze

  attr_reader :pool

  def initialize
    self.pool = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5), timeout: 1) do
      Notifications::Client.new(Rails.configuration.notify_api_key)
    end
  end

  def self.otp_code(mobile_number:, code:)
    instance.pool.with do |client|
      client.send_sms(
        phone_number: mobile_number,
        template_id: TEMPLATES[:otp_code],
        personalisation: { code: code }
      )
    end
  end

private

  attr_writer :pool
end
