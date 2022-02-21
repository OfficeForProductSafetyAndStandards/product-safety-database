class ProductExportJob < ApplicationJob
  def perform(product_export)
    product_export.export!

    NotifyMailer.product_export(
      email: product_export.user.email,
      name: product_export.user.name,
      product_export:
    ).deliver_later
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
