module CoronavirusForm
  extend ActiveSupport::Concern

  included do
    before_action :set_new_coronavirus_form, only: :show, if: -> { step == :coronavirus }
  end

  def set_new_coronavirus_form
    @coronavirus_related_form = CoronavirusRelatedForm.new
  end

  def assigns_coronavirus_related_from_form(investigation, coronvirus_form_params)
    form = coronavirus_related_form(coronvirus_form_params)
    if (form_valid = form.valid?)
      investigation.coronavirus_related = form.coronavirus_related
    end

    form_valid
  end

  def coronavirus_related_form(coronvirus_form_params)
    @coronavirus_related_form ||= CoronavirusRelatedForm.new(coronvirus_form_params)
  end
end
