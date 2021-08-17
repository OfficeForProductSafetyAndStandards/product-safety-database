class CaseExportJob < ApplicationJob
  def perform(case_ids, case_export, user)
    case_export.export case_ids

    NotifyMailer.case_export(
      email: user.email,
      name: user.name,
      case_export: case_export
    ).deliver_later
  end

rescue StandardError => e
  Sentry.capture_exception(e)
  raise
end
