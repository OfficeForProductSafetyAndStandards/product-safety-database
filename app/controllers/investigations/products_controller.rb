class Investigations::ProductsController < ApplicationController
  include CountriesHelper
  include ProductsHelper
  include InvestigationsHelper

  before_action :set_investigation
  before_action :set_product, only: %i[remove unlink]

  def index
    @breadcrumbs = build_breadcrumb_structure
  end

  def new
    authorize @investigation, :update?
    @find_product_form = FindProductForm.new
  end

  def find
    authorize @investigation, :update?
    @find_product_form = FindProductForm.new(find_product_params.merge(investigation: @investigation))
    return render(:new) if @find_product_form.invalid?

    @confirm_product_form = ConfirmProductForm.from_find_product_form(@find_product_form)
    @product = @confirm_product_form.product.decorate
    render :confirm
  end

  def create
    authorize @investigation, :update?
    @confirm_product_form = ConfirmProductForm.new(confirm_product_params)
    @product = @confirm_product_form.product.decorate
    return render(:confirm) if @confirm_product_form.invalid?

    if @confirm_product_form.confirmed?
      AddProductToCase.call! user: current_user, investigation: @investigation, product: @confirm_product_form.product
      redirect_to investigation_products_path(@investigation), flash: { success: "The product record was added to the case" }
    else
      redirect_to new_investigation_product_path
    end
  end

  def remove
    authorize @investigation, :remove_product?

    @supporting_information = @product.supporting_information.select { |si| si.investigation == @investigation }
    render "supporting_information_warning" and return if @product.supporting_information.any?

    @remove_product_form = RemoveProductForm.new
  end

  # DELETE /cases/1/products
  def unlink
    authorize @investigation, :remove_product?
    @remove_product_form = RemoveProductForm.new(remove_product_params)
    return render(:remove) if @remove_product_form.invalid?

    if @remove_product_form.remove_product
      RemoveProductFromCase.call!(investigation: @investigation, product: @product, user: current_user, reason: @remove_product_form.reason)
      respond_to do |format|
        format.html do
          redirect_to_investigation_products_tab success: "Product was successfully removed."
        end
        format.json { head :no_content }
      end
    else
      redirect_to_investigation_products_tab
    end
  end

private

  def redirect_to_investigation_products_tab(flash = nil)
    redirect_to investigation_products_path(@investigation), flash:
  end

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    @investigation = investigation.decorate
  end

  def find_product_params
    params.require(:find_product_form).permit(:reference)
  end

  def confirm_product_params
    params.require(:confirm_product_form).permit(:product_id, :correct)
  end

  def remove_product_params
    params.require(:investigation).permit(:remove_product, :reason)
  end
end
