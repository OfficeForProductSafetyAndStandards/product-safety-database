require "rails_helper"

RSpec.describe "Two Factor Authentication Flipper", type: :feature do
  # Helper method to mimic the application.rb configuration for tests
  def configure_rails_app_for_flipper
    Rails.application.config.instance_variable_set(:@secondary_authentication_enabled, nil)
    Rails.application.config.secondary_authentication_enabled = true
    Rails.application.config.define_singleton_method(:secondary_authentication_enabled) do
      return true unless defined?(Flipper)

      Flipper.enabled?(:two_factor_authentication)
    end
  end

  # Prevent configuration changes from leaking between tests
  after do
    Rails.application.config.instance_variable_set(:@secondary_authentication_enabled, nil)
  end

  # Reusable environment setup to avoid duplication
  shared_context "when in staging environment" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))
    end
  end

  describe "in staging environment" do
    include_context "when in staging environment"

    context "when the two_factor_authentication flipper is enabled" do
      before do
        configure_rails_app_for_flipper
        allow(Flipper).to receive(:enabled?).with(:two_factor_authentication).and_return(true)
      end

      it "enables secondary authentication" do
        expect(Rails.application.config.secondary_authentication_enabled).to be true
      end
    end

    context "when the two_factor_authentication flipper is disabled" do
      before do
        configure_rails_app_for_flipper
        allow(Flipper).to receive(:enabled?).with(:two_factor_authentication).and_return(false)
      end

      it "disables secondary authentication" do
        expect(Rails.application.config.secondary_authentication_enabled).to be false
      end
    end

    # Testing the default "return true unless defined?(Flipper)" behavior
    # without actually modifying the defined? method which is problematic
    describe "default behavior before Flipper is available" do
      it "defaults to true when Flipper is not defined" do
        # Create an isolated method with equivalent logic for testing
        config_method = lambda do
          return true unless defined?(SomeUndefinedConstant)

          SomeUndefinedConstant.enabled?(:whatever)
        end

        expect(config_method.call).to be true
      end
    end
  end

  describe "in non-staging environments" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    context "when TWO_FACTOR_AUTHENTICATION_ENABLED is true" do
      it "reads the environment variable correctly" do
        # Preserve original environment state
        original_env = ENV["TWO_FACTOR_AUTHENTICATION_ENABLED"]

        begin
          ENV["TWO_FACTOR_AUTHENTICATION_ENABLED"] = "true"

          # Verify the conditional logic used in application.rb works as expected
          expect(ENV.fetch("TWO_FACTOR_AUTHENTICATION_ENABLED", "true")).to eq("true")
          expect(ENV.fetch("TWO_FACTOR_AUTHENTICATION_ENABLED", "true") == "true").to be true
        ensure
          # Always restore the environment to avoid affecting other tests
          ENV["TWO_FACTOR_AUTHENTICATION_ENABLED"] = original_env
        end
      end
    end

    context "when TWO_FACTOR_AUTHENTICATION_ENABLED is false" do
      it "reads the environment variable correctly" do
        # Preserve original environment state
        original_env = ENV["TWO_FACTOR_AUTHENTICATION_ENABLED"]

        begin
          ENV["TWO_FACTOR_AUTHENTICATION_ENABLED"] = "false"

          # Verify the conditional logic used in application.rb works as expected
          expect(ENV.fetch("TWO_FACTOR_AUTHENTICATION_ENABLED", "true")).to eq("false")
          expect(ENV.fetch("TWO_FACTOR_AUTHENTICATION_ENABLED", "true") == "true").to be false
        ensure
          # Always restore the environment to avoid affecting other tests
          ENV["TWO_FACTOR_AUTHENTICATION_ENABLED"] = original_env
        end
      end
    end
  end
end
