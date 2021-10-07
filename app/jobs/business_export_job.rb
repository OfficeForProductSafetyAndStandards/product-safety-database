class BusinessExportWorker < ApplicationJob
  def perform(business_ids, business_export, user)
    business_export.export(business_ids)

    NotifyMailer.business_export(
      email: user.email,
      name: user.name,
      business_export: business_export
    ).deliver_later
  end

rescue StandardError => e
  Sentry.capture_exception(e)
  raise
end
