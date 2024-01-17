class DeleteOldExportsJob
  def perform
    delete_old_exports(ProductExport)
    delete_old_exports(NotificationExport)
  end

private

  def delete_old_exports(klass)
    old_exports = klass.where("created_at < ?", 1.week.ago)

    old_exports.each do |export|
      export.export_file.purge if export.export_file.attached?
      export.destroy!
    end
  end
end
