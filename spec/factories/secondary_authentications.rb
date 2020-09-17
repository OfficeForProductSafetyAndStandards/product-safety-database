FactoryBot.define do
  factory :secondary_authentication do
    direct_otp { "123456" }
    user
    operation { SecondaryAuthentication::DEFAULT_OPERATION }
    direct_otp_sent_at { Time.zone.now.utc }
    authenticated { false }
  end
end
