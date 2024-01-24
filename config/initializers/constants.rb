Rails.application.config.legislation_constants = YAML.load_file(
  Rails.root.join("config/constants/legislation_constants.yml")
)
Rails.application.config.hazard_constants = YAML.load_file(
  Rails.root.join("config/constants/hazard_constants.yml")
)
Rails.application.config.product_constants = YAML.load_file(
  Rails.root.join("config/constants/product_constants.yml")
)
Rails.application.config.corrective_action_constants = YAML.load_file(
  Rails.root.join("config/constants/corrective_action_constants.yml")
)
Rails.application.config.team_names = YAML.load_file(
  Rails.root.join("config/constants/important_team_names.yml")
)
Rails.application.config.whitelisted_emails = YAML.load_file(
  Rails.root.join("config/constants/whitelisted_emails.yml")
)
Rails.application.config.domains_allowing_otp_whitelisting = YAML.load_file(
  Rails.root.join("config/constants/domains_allowing_otp_whitelisting.yml"),
  permitted_classes: [Regexp]
)
Rails.application.config.statistics = YAML.load_file(
  Rails.root.join("config/constants/statistics.yml")
)
