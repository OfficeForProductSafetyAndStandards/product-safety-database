Rails.application.config.after_initialize do
  require "i18n-js/listen"
  I18nJS.listen(
    config_file: Prism::Engine.root.join("config/i18n.yml"),
    locales_dir: [Prism::Engine.root.join("config/locales")],
  )
end
