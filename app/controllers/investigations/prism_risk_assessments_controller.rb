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
        .submitted
        .where(prism_associated_products: { product_id: @product.id })
        .or(PrismRiskAssessment.where.not(prism_associated_investigations: { investigation_id: @investigation.id }).where(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @product.id } }))
        .order(updated_at: :desc)
    end

    def create
      return render :new if params[:prism_risk_assessment_id].blank?

      prism_risk_assessment = PrismRiskAssessment.find(params[:prism_risk_assessment_id])
      ActiveRecord::Base.transaction do
        # When a PRISM risk assessment is associated with a case, any direct product associations are deleted
        prism_risk_assessment.prism_associated_products.destroy_all
        # rubocop:disable Rails/SaveBang
        if prism_risk_assessment.prism_associated_investigations.create(investigation_id: @investigation.id, prism_associated_investigation_products_attributes: [{ product_id: params[:product_id] }])
          redirect_to investigation_path(@investigation), flash: { success: "The risk assessment has been added to the case." }
        else
          render :new
        end
        # rubocop:enable Rails/SaveBang
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
