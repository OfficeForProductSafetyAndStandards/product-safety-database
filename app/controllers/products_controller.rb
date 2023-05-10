class ProductsController < ApplicationController
  include CountriesHelper
  include ProductsHelper
  include UrlHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_product, only: %i[show edit update owner]
  before_action :set_countries, only: %i[new update edit]
  before_action :build_breadcrumbs, only: %i[show]
  before_action :set_sort_by_items, only: %i[index your_products team_products]

  # GET /products
  # GET /products.json
  def index
    respond_to do |format|
      format.html do
        @results = search_for_products(20)
        @count = count_to_display
        @products = ProductDecorator.decorate_collection(@results)
        @page_name = "all_products"
      end
    end
  end

  def show
    # Anyone can view timestamped products, but only certain people can view live [retired] products
    return render "/products/retired" unless policy(@product).show?
  end

  # GET /products/new
  def new
    @product_form = ProductForm.new
    @product_form.barcode = params[:barcode] if params[:barcode].present?
  end

  def owner
    render_404_page and return if !policy(@product).show? || @product.owning_team.blank?
  end

  # POST /products
  def create
    @product_form = ProductForm.new product_params

    respond_to do |format|
      if @product_form.valid?
        context = CreateProduct.call!(
          @product_form.serializable_hash.merge(user: current_user)
        )
        @product = context.product
        format.html { render :confirmation }
      else
        set_countries
        format.html { render :new }
      end
    end
  end

  # GET /products/1/edit
  def edit
    authorize @product, :update?

    @product_form = ProductForm.from @product.object
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    authorize @product, :update?

    respond_to do |format|
      @product_form = ProductForm.from @product.object
      @product_form.attributes = product_params_for_update

      if @product_form.valid?
        format.html do
          UpdateProduct.call!(
            product: @product.object,
            product_params: @product_form.serializable_hash,
            updating_team: current_user.team
          )

          redirect_to product_path(@product), flash: { success: "The product record was updated" }
        end
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def your_products
    @search = SearchParams.new({ "case_owner" => "me",
                                 "case_status" => "open_only",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => "your_products" })
    @results = search_for_products(20)
    @count = @results.total_count
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
    @results = search_for_products(20)
    @count = @results.total_count
    @products = ProductDecorator.decorate_collection(@results)
    @page_name = "team_products"

    render "products/index"
  end

private

  def build_breadcrumbs
    @breadcrumbs = build_back_link_to_case || build_breadcrumb_structure
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
      SortByHelper::SortByItem.new("Name A–Z", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_ASC),
      SortByHelper::SortByItem.new("Name Z–A", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_DESC)
    ]
    items.unshift(SortByHelper::SortByItem.new("Relevance", SortByHelper::SORT_BY_RELEVANT, SortByHelper::SORT_DIRECTION_DEFAULT)) if params[:q].present?
    items
  end

  def count_to_display
    params[:category].blank? && params[:q].blank? && [nil, "active"].include?(params[:retired_status]) ? Product.not_retired.count : @results.total_count
  end
end
