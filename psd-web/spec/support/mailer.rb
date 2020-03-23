# frozen_string_literal: true

TestNotifyEmail = Struct.new(:recipient, :personalization)

RSpec.shared_context "with stubbed mailer", shared_context: :metadata do
  let!(:delivered_emails) { [] }
  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(NotifyMailer).to receive(:mail).and_wrap_original do |m, *args|
      delivered_emails << TestNotifyEmail.new(*args.first, m.receiver.govuk_notify_personalisation)
    end
  end
  # rubocop:enable RSpec/AnyInstance
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed mailer", with_stubbed_mailer: true
end
