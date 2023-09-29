class PrismRiskAssessmentsController < ApplicationController
  include BreadcrumbHelper

  breadcrumb "prism_risk_assessments.label", :all_prism_risk_assessments

  before_action :set_search_params, only: %i[index]
  before_action :set_sort_by_items, only: %i[index your_prism_risk_assessments team_prism_risk_assessments]
  before_action :set_last_prism_risk_assessment_view_cookie, only: %i[index your_prism_risk_assessments team_prism_risk_assessments]

  def index
    authorize PrismRiskAssessment, :index?

    @submitted_prism_risk_assessments = PrismRiskAssessment.submitted

    if @search.q
      @search.q.strip!
      @submitted_prism_risk_assessments = @submitted_prism_risk_assessments
        .joins(:prism_product_market_detail)
        .left_joins(prism_associated_products: :product)
        .left_joins(prism_associated_investigation_products: :product)
        .where("prism_risk_assessments.name ILIKE ?", "%#{@search.q}%")
        .or(PrismRiskAssessment.where("prism_product_market_details.selling_organisation ILIKE ?", "%#{@search.q}%"))
        .or(PrismRiskAssessment.where("products.name ILIKE ?", "%#{@search.q}%"))
        .or(PrismRiskAssessment.where("products_prism_associated_investigation_products.name ILIKE ?", "%#{@search.q}%"))
    end

    @submitted_prism_risk_assessments = @submitted_prism_risk_assessments.order(sorting_params).page(params[:submitted_page]).per(20)
    @count = @submitted_prism_risk_assessments.total_count
    @page_name = "all_prism_risk_assessments"
  end

  def your_prism_risk_assessments
    authorize PrismRiskAssessment, :index?

    @draft_prism_risk_assessments = PrismRiskAssessment.for_user(current_user).draft.order(sorting_params).page(params[:draft_page]).per(20)
    @submitted_prism_risk_assessments = PrismRiskAssessment.for_user(current_user).submitted.order(sorting_params).page(params[:submitted_page]).per(20)
    @count = @draft_prism_risk_assessments.total_count + @submitted_prism_risk_assessments.total_count
    @page_name = "your_prism_risk_assessments"

    render "prism_risk_assessments/index"
  end

  def team_prism_risk_assessments
    authorize PrismRiskAssessment, :index?

    @submitted_prism_risk_assessments = PrismRiskAssessment.for_team(current_user.team).submitted.order(sorting_params).page(params[:submitted_page]).per(20)
    @count = @submitted_prism_risk_assessments.total_count
    @page_name = "team_prism_risk_assessments"

    render "prism_risk_assessments/index"
  end

  def add_to_case
    return redirect_to your_prism_risk_assessments_path if params[:prism_risk_assessment_id].blank? || (params[:investigation_pretty_id].blank? && request.post?)

    @prism_risk_assessment = PrismRiskAssessment.find(params[:prism_risk_assessment_id])
    # Find all submitted PRISM risk assessments that are associated with the chosen product
    # either directly or via a case that is not the current case.
    @related_investigations = Investigation
      .left_joins(:investigation_products, prism_associated_investigations: :prism_associated_investigation_products)
      .where.missing(:prism_associated_investigations)
      .or(Investigation.where.not(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @prism_risk_assessment.product_id } }))
      .where(investigation_products: { product_id: @prism_risk_assessment.product_id })
      .where(is_closed: false)
      .order(updated_at: :desc)
      .decorate

    if request.post?
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      product = Product.find(@prism_risk_assessment.product_id)

      if AddPrismRiskAssessmentToCase.call(investigation:, product:, prism_risk_assessment: @prism_risk_assessment)
        redirect_to investigation_path(params[:investigation_pretty_id]), flash: { success: "The #{@prism_risk_assessment.name} risk assessment has been added to the case." }
      else
        render :add_to_case
      end
    end
  end

private

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def query_params
    params.permit(:q, :sort_by, :sort_dir, :page_name)
  end

  def set_last_prism_risk_assessment_view_cookie
    cookies[:last_prism_risk_assessment_view] = params[:action]
  end

  def set_sort_by_items
    @sort_by_items = sort_by_items
    @selected_sort_by = params[:sort_by].presence || SortByHelper::SORT_BY_UPDATED_AT
    @selected_sort_direction = params[:sort_dir]
  end

  def sort_by_items
    [
      SortByHelper::SortByItem.new("Recent updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_DESC),
      SortByHelper::SortByItem.new("Oldest updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_ASC),
      SortByHelper::SortByItem.new("Assessment title A–Z", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_ASC),
      SortByHelper::SortByItem.new("Assessment title Z–A", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_DESC)
    ]
  end

  def sorting_params
    return { name: :desc } if params[:sort_by] == SortByHelper::SORT_BY_NAME && params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC
    return { name: :asc } if params[:sort_by] == SortByHelper::SORT_BY_NAME
    return { updated_at: :asc } if params[:sort_by] == SortByHelper::SORT_BY_UPDATED_AT && params[:sort_dir] == SortByHelper::SORT_DIRECTION_ASC

    { updated_at: :desc }
  end
end
