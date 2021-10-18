class ProductExportJob < ApplicationJob
  def perform(product_ids, product_export, user)
    product_export.export(product_ids)

    NotifyMailer.product_export(
      email: user.email,
      name: user.name,
      product_export: product_export
    ).deliver_later
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
