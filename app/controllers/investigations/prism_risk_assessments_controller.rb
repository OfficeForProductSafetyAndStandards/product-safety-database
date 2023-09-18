module Investigations
  class PrismRiskAssessmentsController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs
    before_action :ensure_one_product, except: %i[choose_product]
    before_action :product, except: %i[choose_product]

    def new
      # Find all submitted PRISM risk assessments that are associated with the chosen product
      # either directly or via a case that is not the current case.
      @related_prism_risk_assessments = PrismRiskAssessment
        .left_joins(:prism_associated_products, prism_associated_investigations: :prism_associated_investigation_products)
        .where(prism_associated_products: { product_id: @product.id })
        .or(PrismRiskAssessment.where(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @product.id } }))
        .where.not(id:
          PrismRiskAssessment
            .left_joins(prism_associated_investigations: :prism_associated_investigation_products)
            .where(prism_associated_investigations: { investigation_id: @investigation.id }).where(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @product.id } })
            .submitted
            .distinct)
        .submitted
        .order(updated_at: :desc)
    end

    def create
      return render :new if params[:prism_risk_assessment_id].blank?

      prism_risk_assessment = PrismRiskAssessment.find(params[:prism_risk_assessment_id])
      product = Product.find(prism_risk_assessment.product_id)

      if AddPrismRiskAssessmentToCase.call(investigation: @investigation, product:, prism_risk_assessment:)
        redirect_to investigation_path(@investigation), flash: { success: "The #{prism_risk_assessment.name} risk assessment has been added to the case." }
      else
        render :new
      end
    end

    def choose_product
      @products = @investigation.products
    end

  private

    def ensure_one_product
      return if @investigation.products.size == 1

      redirect_to choose_product_investigation_prism_risk_assessments_path unless params[:product_id].present? && @investigation.products.find_by(id: params[:product_id])
    end

    def product
      @product ||= params[:product_id].present? ? @investigation.products.find(params[:product_id]) : @investigation.products.first!
    end
  end
end
