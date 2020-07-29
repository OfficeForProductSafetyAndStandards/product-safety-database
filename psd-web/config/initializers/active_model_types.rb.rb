require "types/file_form"
require "types/date_form"

ActiveModel::Type.register(:file_form, ::FileForm)
ActiveModel::Type.register(:date_form, ::DateForm)
