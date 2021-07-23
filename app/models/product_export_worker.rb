class ProductExportWorker < ApplicationJob
  def perform(products, product_export_id, user)
    product_export = ProductExport.find(product_export_id)
    return unless product_export

    product_export.export(products)

    NotifyMailer.product_export(
      email: user.email,
      name: user.name,
      product_export: product_export
    ).deliver_later
  end

rescue StandardError => e
  Sentry.capture_exception(e)
  raise
end
