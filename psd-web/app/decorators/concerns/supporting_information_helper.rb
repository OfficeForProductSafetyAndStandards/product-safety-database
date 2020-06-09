module SupportingInformationHelper
  extend ActiveSupport::Concern
  def type_for_table_display
    object.class.model_name.human
  end
end
