require_relative "lib/prism/version"

Gem::Specification.new do |spec|
  spec.name        = "prism"
  spec.version     = Prism::VERSION
  spec.authors     = ["Office for Product Safety and Standards"]
  spec.email       = ["opss.enquiries@businessandtrade.gov.uk"]
  spec.homepage    = "https://github.com/OfficeForProductSafetyAndStandards/product-safety-database"
  spec.summary     = "Product Safety Risk Assessment Methodology"
  spec.description = "PRISM is a product safety risk assessment tool, part of the Product Safety Database (PSD)."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org.
  # Set a fake URL here since we're not publishing this engine as a gem.
  spec.metadata["allowed_push_host"] = "https://www.product-safety-database.service.gov.uk"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/OfficeForProductSafetyAndStandards/product-safety-database"
  spec.metadata["changelog_uri"] = "https://github.com/OfficeForProductSafetyAndStandards/product-safety-database/blob/develop/prism/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "Rakefile", "README.md"]
  end

  # This should be kept in sync with the Ruby version used by the main app
  spec.required_ruby_version = ">= 3.3.4"

  # Ensure any gems that are also used in the main app have the same version constraints
  # Run `bundle install` for both this engine and the main app when adding or changing gems
  spec.add_runtime_dependency "aasm", "~> 5.5"
  spec.add_runtime_dependency "active_storage_validations", "~> 1.0"
  spec.add_runtime_dependency "aws-sdk-s3", "~> 1.122"
  spec.add_runtime_dependency "devise", "~> 4.9"
  spec.add_runtime_dependency "govuk-components", "~> 5.0"
  spec.add_runtime_dependency "govuk_design_system_formbuilder", "~> 5.0"
  spec.add_runtime_dependency "listen", "~> 3.8"
  spec.add_runtime_dependency "pagy", ">= 6", "< 10"
  spec.add_runtime_dependency "pg", "~> 1.5"
  spec.add_runtime_dependency "prawn", "~> 2.4"
  spec.add_runtime_dependency "prawn-table", "~> 0.2"
  spec.add_runtime_dependency "rails", ">= 7.1.3.2"
  spec.add_runtime_dependency "store_attribute", ">= 1.1", "< 3.0"
  spec.add_runtime_dependency "wicked", "~> 2.0"
end
