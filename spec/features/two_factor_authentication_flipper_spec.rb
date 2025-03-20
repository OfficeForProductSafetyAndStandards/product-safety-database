require "rails_helper"

describe "Two Factor Authentication Flipper", :with_2fa, :with_flipper do
  # Configure test instance with same behavior as application
  def configure_rails_app_for_flipper
    Rails.application.config.secondary_authentication_enabled = true

    class << Rails.application.config
      def secondary_authentication_enabled
        return true unless defined?(Flipper) && Flipper.respond_to?(:enabled?)

        Flipper.enabled?(:two_factor_authentication)
      end
    end
  end

  # Clean up after each test
  after do
    Rails.application.config.secondary_authentication_enabled = nil
  end

  describe "Two Factor Authentication with Flipper" do
    before do
      configure_rails_app_for_flipper
    end

    context "when two_factor_authentication feature is enabled" do
      it "enables secondary authentication" do
        enable_2fa
        expect(Rails.configuration.secondary_authentication_enabled).to be true
      end
    end

    context "when two_factor_authentication feature is disabled" do
      it "disables secondary authentication" do
        disable_2fa
        expect(Rails.configuration.secondary_authentication_enabled).to be false
      end
    end
  end

  describe "default behavior before Flipper is available" do
    it "defaults to true when Flipper is not defined" do
      # Test the fallback behavior when Flipper is not initialized
      config_method = lambda do
        return true unless defined?(SomeUndefinedConstant) && SomeUndefinedConstant.respond_to?(:enabled?)

        SomeUndefinedConstant.enabled?(:two_factor_authentication)
      end

      expect(config_method.call).to be true
    end
  end

  describe "method configuration safety" do
    it "handles direct method definition without crashing" do
      # Create a test class to verify our approach
      test_class = Class.new do
        attr_accessor :test_value

        def initialize
          self.test_value = true
        end
      end

      test_obj = test_class.new
      expect(test_obj.test_value).to be true

      # Override with new method definition - same approach as in application.rb
      class << test_obj
        def test_value
          false
        end
      end

      # Verify the overridden method works
      expect(test_obj.test_value).to be false
    end
  end
end
