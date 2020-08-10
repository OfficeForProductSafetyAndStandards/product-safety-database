module FlowWithCoronavirusForm
  extend ActiveSupport::Concern

  included do
    before_action :set_new_coronavirus_form, only: :show, if: -> { step == :coronavirus }
    before_action :set_coronavirus_form_from_params, only: :update, if: -> { step == :coronavirus }
  end

  def set_new_coronavirus_form
    @coronavirus_related_form = CoronavirusRelatedForm.new
  end

  def set_coronavirus_form_from_params
    @coronavirus_related_form = CoronavirusRelatedForm.new(coronavirus_form_params)
  end

  def assigns_coronavirus_related_from_form(investigation, form)
    if (form_valid = form.valid?)
      investigation.coronavirus_related = form.coronavirus_related
    end

    form_valid
  end
end
