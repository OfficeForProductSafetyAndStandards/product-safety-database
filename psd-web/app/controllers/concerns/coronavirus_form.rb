module CoronavirusForm
  extend ActiveSupport::Concern

  included do
    before_action :set_new_coronavirus_form, only: :show, if: -> { step == :coronavirus }
  end

  def set_coronavirus_info_from_form
    if coronavirus_related_form.valid?
      @investigation.coronavirus_related = coronavirus_related_form.coronavirus_related
    end
  end

  def coronavirus_related_form
    @coronavirus_related_form ||= CoronavirusRelatedForm.new(params.require(:investigation).permit(:coronavirus_related))
  end
end
