require_relative "lib/prism/version"

Gem::Specification.new do |spec|
  spec.name        = "prism"
  spec.version     = Prism::VERSION
  spec.authors     = ["Office for Product Safety and Standards"]
  spec.email       = ["opss.enquiries@beis.gov.uk"]
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

  spec.required_ruby_version = ">= 3.2.1"

  spec.add_runtime_dependency "aasm", "~> 5.5"
  spec.add_runtime_dependency "aws-sdk-s3", "~> 1.122"
  spec.add_runtime_dependency "govuk-components", "~> 4.0"
  spec.add_runtime_dependency "kaminari", "~> 1.2"
  spec.add_runtime_dependency "pg", "~> 1.5"
  spec.add_runtime_dependency "rails", ">= 7.0.4.3"
  spec.add_runtime_dependency "wicked", "~> 2.0"

  spec.add_development_dependency "rspec-rails"
end