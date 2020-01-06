# frozen_string_literal: true

RSpec.shared_context "with stubbed mailer", shared_context: :metadata do
  before { allow_any_instance_of(NotifyMailer).to receive(:mail) { true } }
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed mailer", with_stubbed_mailer: true
end
