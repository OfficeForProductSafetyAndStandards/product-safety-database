class Investigations::SummaryController < ApplicationController
  # GET /cases/1/summary/edit
  def edit
    investigation = Investigation.includes(:teams_with_edit_access).find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @form = ChangeCaseSummaryForm.new(summary: investigation.description)
    @investigation = investigation.decorate
  end

  # PATCH /cases/1/summary
  def update
    investigation = Investigation.includes(:teams_with_edit_access).find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @form = ChangeCaseSummaryForm.new(params.require(:change_case_summary_form).permit(:summary))

    unless @form.valid?
      @investigation = investigation.decorate

      return respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @form.errors, status: :unprocessable_entity }
      end
    end

    ChangeCaseSummary.call!(investigation:, summary: @form.summary, user: current_user)

    respond_to do |format|
      format.html do
        redirect_to investigation_path(investigation),
                    flash: { success: "Case was successfully updated" }
      end
      format.json { render :show, status: :ok, location: investigation }
    end
  end
end
