class CaseExportJob < ApplicationJob
  def perform(case_export)
    case_export.export!

    NotifyMailer.case_export(
      email: case_export.user.email,
      name: case_export.user.name,
      case_export: case_export
    ).deliver_later
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
