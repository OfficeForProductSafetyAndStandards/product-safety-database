module SupportingInformationHelper
  extend ActiveSupport::Concern
  def supporting_information_type
    object.class.model_name.human
  end
end
