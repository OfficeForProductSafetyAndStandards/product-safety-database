class BusinessExportJob < ApplicationJob
  def perform(business_export)
    business_export.export!

    NotifyMailer.business_export(
      email: business_export.user.email,
      name: business_export.user.name,
      business_export:
    ).deliver_later
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
