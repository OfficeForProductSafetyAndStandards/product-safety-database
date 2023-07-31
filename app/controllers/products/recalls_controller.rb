module Products
  class RecallsController < ApplicationController
    include Wicked::Wizard
    include CountriesHelper

    layout "tool"

    steps :start, :"select-images", :"product-details", :complete

    before_action :authorize_user
    before_action :product
    before_action :case
    before_action :online_marketplaces, only: %i[show update]

    def show
      @form = ProductRecallForm.new
      render_wizard
    end

    def update
      @form = ProductRecallForm.new(recall_form_params)
      unless @form.last_step?
        @form.advance!
        render_wizard
      end
    end

    def pdf
      @form = ProductRecallForm.new(recall_form_params)
      filetype = product_safety_report? ? "product-safety-report" : "product-recall"
      filename = "#{@product.investigations&.first&.pretty_id}-#{filetype}-#{@form.attributes['pdf_title']&.parameterize}"
      send_data(GenerateProductRecallPdf.new(@form.attributes, @product).render, filename:, type: "application/pdf", disposition: "attachment")
    end

  private

    def authorize_user
      redirect_to "/403" if current_user && !current_user.can_use_product_recall_tool?
    end

    def product
      @product ||= Product.find(params[:product_id]).decorate
    end

    def case
      @case ||= @product.investigations&.first
    end

    def online_marketplaces
      @online_marketplaces = OnlineMarketplace.approved.order(:name)
    end

    def recall_form_params
      params.require(:product_recall_form).permit(
        :step, :type, :pdf_title, :alert_number, :product_type, :product_identifiers, :product_description,
        :country_of_origin, :counterfeit, :risk_type, :risk_level, :risk_description, :online_marketplace,
        :online_marketplace_id, :other_marketplace_name, :other_corrective_action, corrective_actions: [],
                                                                                   product_image_ids: []
      )
    end

    def product_safety_report?
      @form.attributes["type"] == "product_safety_report"
    end
  end
end
