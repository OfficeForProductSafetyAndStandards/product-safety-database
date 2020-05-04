# frozen_string_literal: true

RSpec.shared_context "with exception errors", shared_context: :metadata do
  before do
    allow(Rails.application).to receive(:env_config).with(no_args).and_wrap_original do |m|
      m.call.merge(
        "consider_all_requests_local" => false,
        "action_dispatch.show_exceptions" => true,
        "action_dispatch.show_detailed_exceptions" => false
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with exception errors", with_exception_errors: true
end
