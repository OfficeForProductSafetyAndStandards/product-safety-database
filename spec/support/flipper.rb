# frozen_string_literal: true

require "flipper"
require "flipper/adapters/memory"

RSpec.configure do |config|
  # Configure isolated Flipper instance for testing
  config.before(:each, :with_flipper) do
    # Use memory adapter to avoid affecting the database
    memory_adapter = Flipper::Adapters::Memory.new
    flipper_instance = Flipper.new(memory_adapter)

    # Configure test environment to use our isolated Flipper
    allow(Flipper).to receive(:new).and_return(flipper_instance)
    allow(Flipper).to receive(:enabled?).and_call_original
  end

  # Default configuration for 2FA feature flag tests
  config.before(:each, :with_2fa) do
    allow(Flipper).to receive(:enabled?).with(:two_factor_authentication).and_return(true)
  end

  # Helper methods for feature flag testing
  config.include Module.new {
    # Generic feature flag controls
    def enable_feature(feature_name)
      Flipper.enable(feature_name)
    end

    def disable_feature(feature_name)
      Flipper.disable(feature_name)
    end

    # 2FA-specific test helpers
    def enable_2fa
      allow(Flipper).to receive(:enabled?).with(:two_factor_authentication).and_return(true)
    end

    def disable_2fa
      allow(Flipper).to receive(:enabled?).with(:two_factor_authentication).and_return(false)
    end
  }, :with_flipper
end
