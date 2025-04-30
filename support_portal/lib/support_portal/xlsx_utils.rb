module SupportPortal
  module XlsxUtils
  private

    def serialize_to_file(type:, axlsx_package:)
      output_directory = Rails.root.join("tmp/#{type}/")
      output_file = output_directory.join("#{type}-#{Time.zone.now.strftime('%Y-%m-%dT%H%M%S%z')}.xlsx")
      FileUtils.mkdir_p(output_directory)
      axlsx_package.serialize(output_file)
      output_file
    end

    def attach_to_model(model:, file:)
      model.purge if model.attached?

      model.attach(
        io: File.open(file),
        filename: File.basename(file),
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        identify: false
      )
    end
  end
end
