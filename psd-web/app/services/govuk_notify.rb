class GovukNotify
  include Singleton

  TEMPLATES = {
    send_otp_code: "33517ff-2a88-4f6e-b855-c550268ce08a"
  }

  attr_reader :pool

  def initialize
    self.pool = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5), timeout: 1) do
      Notifications::Client.new(Rails.configuration.notify_api_key)
    end
  end

  def self.send_otp_code(mobile_number: , code:)
    instance.pool.with do |client|
      client.send_sms(
        mobile_number: mobile_number,
        template_id: TEMPLATES[:send_otp_code],
        personalisation: { code: code }
      )
    end
  end

  private

  attr_writer :pool
end
