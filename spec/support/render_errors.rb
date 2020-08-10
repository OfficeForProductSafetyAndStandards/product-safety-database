# frozen_string_literal: true

# This shared context allows an individual test to temporarily turn
# on error page rendering (rather than raising an exception) in order to
# allow assertions based upon the rendered error page.
#
# Due to Rails config caching, this has to alter `env_config` directly
# rather than setting Rails.application.config.action_dispatch.show_exception
#
# See https://github.com/rspec/rspec-rails/issues/2024
RSpec.shared_context "with errors rendered" do
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
  rspec.include_context "with errors rendered", with_errors_rendered: true
end
