module SupportingInformationHelper
  extend ActiveSupport::Concern
  def supporting_information_type
    object.class.model_name.human
  end

  def activity_cell_partial(_viewing_user)
    "activity_table_cell_with_link"
  end
end
