class BusinessesController < ApplicationController
  include BusinessesHelper
  include UrlHelper
  include CountriesHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_business, only: %i[show edit update]
  before_action :update_business, only: %i[update]
  before_action :build_breadcrumbs, only: %i[show]
  before_action :set_countries, only: %i[update edit]
  before_action :set_sort_by_items, only: %i[index]

  # GET /businesses
  # GET /businesses.json
  def index
    respond_to do |format|
      format.html do
        results = search_for_businesses(20)
        @businesses = BusinessDecorator.decorate_collection(results)
      end
    end
  end

  # GET /businesses/1
  # GET /businesses/1.json
  def show
    @business = @business.decorate
  end

  # GET /businesses/1/edit
  def edit
    @business.locations.build unless @business.locations.any?
  end

  # PATCH/PUT /businesses/1
  # PATCH/PUT /businesses/1.json
  def update
    respond_to do |format|
      if @business.save
        @business.investigations.import
        format.html { redirect_to @business, flash: { success: "Business was successfully updated." } }
        format.json { render :show, status: :ok, location: @business }
      else
        format.html { render :edit }
        format.json { render json: @business.errors, status: :unprocessable_entity }
      end
    end
  end

private

  def update_business
    @business.assign_attributes(business_params)
    defaults_on_primary_location(@business) if @business.locations.any?
  end

  def build_breadcrumbs
    @breadcrumbs = build_back_link_to_case || build_breadcrumb_structure
  end

  def set_sort_by_items
    params[:sort_by] = SortByHelper::SORT_BY_RELEVANT if params[:sort_by].blank? && params[:q].present?
    params[:sort_by] = nil if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT && params[:q].blank?

    @sort_by_items = sort_by_items
    @selected_sort_by = params[:sort_by].presence || SortByHelper::SORT_BY_RECENT
    @selected_sort_direction = params[:sort_dir]
  end

  def sort_by_items
    items = [
      SortByHelper::SortByItem.new("Recently added", SortByHelper::SORT_BY_RECENT, SortByHelper::SORT_DIR_DEFAULT),
      SortByHelper::SortByItem.new("Name A–Z", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIR_ASC),
      SortByHelper::SortByItem.new("Name Z–A", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIR_DESC)
    ]
    items.unshift(SortByHelper::SortByItem.new("Relevance", SortByHelper::SORT_BY_RELEVANT, SortByHelper::SORT_DIR_DEFAULT)) if params[:q].present?
    items
  end
end
