class ProductsController < ApplicationController
  include CountriesHelper
  include ProductsHelper
  include UrlHelper
  include BreadcrumbHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_product, only: %i[show edit update owner]
  before_action :set_countries, only: %i[new update edit]
  before_action :set_sort_by_items, only: %i[index your_products team_products]
  before_action :set_last_product_view_cookie, only: %i[index your_products team_products]

  breadcrumb "products.label", :products_path

  def index
    # Find the most recent incomplete bulk products upload for the current user, if any
    @incomplete_bulk_products_upload = BulkProductsUpload.where(user: current_user, submitted_at: nil).order(updated_at: :desc).first
    @pagy, @results = search_for_products
    @count = count_to_display
    @products = ProductDecorator.decorate_collection(@results)
    @page_name = "all_products"
  end

  def show
    # Anyone can view timestamped products, but only certain people can view live [retired] products
    return render "/products/retired" unless policy(@product).show?

    breadcrumb breadcrumb_product_label, breadcrumb_product_path
  end

  def new
    @product_form = ProductForm.new
    @product_form.barcode = params[:barcode] if params[:barcode].present?
  end

  def owner
    render_404_page and return if !policy(@product).show? || @product.owning_team.blank?
  end

  def create
    @product_form = ProductForm.new(product_params)

    if @product_form.valid?
      context = CreateProduct.call!(
        @product_form.serializable_hash.merge(user: current_user)
      )
      @product = context.product
      @product_form.cache_file!(current_user, @product)

      return redirect_to add_product_notification_create_index_path(notification_pretty_id: product_params[:notification_pretty_id], product_id: @product.id) if product_params[:notification_pretty_id].present?

      render :confirmation
    else
      set_countries
      @product_form.cache_file!(current_user, nil)
      render :new
    end
  end

  def edit
    authorize @product, :update?

    @product_form = ProductForm.from(@product.object)
    breadcrumb breadcrumb_product_label, breadcrumb_product_path
    breadcrumb @product.name, product_path(@product)
  end

  def update
    authorize @product, :update?

    @product_form = ProductForm.from(@product.object)
    @product_form.attributes = product_params_for_update

    if @product_form.valid?
      UpdateProduct.call!(
        product: @product.object,
        product_params: @product_form.serializable_hash.except("image", "existing_image_file_id", "notification_pretty_id"),
        updating_team: current_user.team
      )
      ahoy.track "Updated product", { product_id: @product.id, product_name: @product.name, updating_team: current_user.team }

      redirect_to product_path(@product), flash: { success: "The product record was updated" }
    else
      render :edit
    end
  end

  def your_products
    @search = SearchParams.new({ "case_owner" => "me",
                                 "case_status" => "open_only",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => "your_products" })
    @pagy, @results = search_for_products
    @count = @pagy.count
    @products = ProductDecorator.decorate_collection(@results)
    @page_name = "your_products"

    render "products/index"
  end

  def team_products
    @search = SearchParams.new({ "case_owner" => "my_team",
                                 "case_status" => "open_only",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => "team_products" })
    @pagy, @results = search_for_products
    @count = @pagy.count
    @products = ProductDecorator.decorate_collection(@results)
    @page_name = "team_products"

    render "products/index"
  end

private

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def product_params
    params.require(:product).permit(
      :name, :brand, :category, :subcategory, :product_code,
      :image, :existing_image_file_id, :notification_pretty_id,
      :webpage, :description, :country_of_origin, :barcode,
      :authenticity, :when_placed_on_market, :has_markings, markings: []
    )
  end

  def product_params_for_update
    params.require(:product).permit(
      :subcategory, :product_code,
      :webpage, :description, :country_of_origin, :barcode,
      :when_placed_on_market, :has_markings, markings: []
    )
  end

  def query_params
    params.permit(:q, :sort_by, :sort_dir, :direction, :category, :retired_status, :page_name, :notification, :allegation, :enquiry, :project, countries: [])
  end

  def set_last_product_view_cookie
    cookies[:last_product_view] = params[:action]
  end

  def set_sort_by_items
    params[:sort_by] = SortByHelper::SORT_BY_RELEVANT if params[:sort_by].blank? && params[:q].present?
    params[:sort_by] = nil if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT && params[:q].blank?

    @sort_by_items = sort_by_items
    @selected_sort_by = params[:sort_by].presence || SortByHelper::SORT_BY_CREATED_AT
    @selected_sort_direction = params[:sort_dir]
  end

  def sort_by_items
    items = [
      SortByHelper::SortByItem.new("Newly added", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_DEFAULT),
      SortByHelper::SortByItem.new("Name A-Z", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_ASC),
      SortByHelper::SortByItem.new("Name Z-A", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_DESC)
    ]
    items.unshift(SortByHelper::SortByItem.new("Relevance", SortByHelper::SORT_BY_RELEVANT, SortByHelper::SORT_DIRECTION_DEFAULT)) if params[:q].present?
    items
  end

  def count_to_display
    return @pagy.count unless filters_empty?
    return Product.not_retired.count if current_user.is_opss?

    Product.not_retired.joins(:investigations).where(investigations: { type: ["Investigation::Notification", nil] }).count
  end

  def filters_empty?
    params[:category].blank? &&
      params[:q].blank? &&
      [nil, "active"].include?(params[:retired_status]) &&
      params[:countries].blank? &&
      params[:notification].blank? &&
      params[:allegation].blank? &&
      params[:enquiry].blank? &&
      params[:project].blank?
  end
end
