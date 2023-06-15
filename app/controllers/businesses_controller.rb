class BusinessesController < ApplicationController
  include BusinessesHelper
  include UrlHelper
  include CountriesHelper
  include BreadcrumbHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_business, only: %i[show edit update]
  before_action :update_business, only: %i[update]
  before_action :set_countries, only: %i[update edit]
  before_action :set_sort_by_items, only: %i[index your_businesses team_businesses]
  before_action :set_last_business_view_cookie, only: %i[index your_businesses team_businesses ]

  breadcrumb "businesses.label", :businesses_path

  # GET /businesses
  # GET /businesses.json
  def index
    respond_to do |format|
      format.html do
        @results = search_for_businesses(20)
        @count = count_to_display
        @businesses = BusinessDecorator.decorate_collection(@results)
        @page_name = "all_businesses"
      end
    end
  end

  # GET /businesses/1
  # GET /businesses/1.json
  def show
    @business = @business.decorate
    breadcrumb breadcrumb_business_label, breadcrumb_business_path
  end

  # GET /businesses/1/edit
  def edit
    @business.locations.build unless @business.locations.any?
    breadcrumb breadcrumb_business_label, breadcrumb_business_path
  end

  # PATCH/PUT /businesses/1
  # PATCH/PUT /businesses/1.json
  def update
    respond_to do |format|
      if @business.save
        @business.investigations.not_deleted.import
        format.html { redirect_to @business, flash: { success: "The business was updated" } }
        format.json { render :show, status: :ok, location: @business }
      else
        format.html { render :edit }
        format.json { render json: @business.errors, status: :unprocessable_entity }
      end
    end
  end

  def your_businesses
    @search = SearchParams.new({ "case_owner" => "me",
                                 "case_status" => "open_only",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => "your_businesses" })
    @results = search_for_businesses(20)
    @count = @results.total_count
    @businesses = BusinessDecorator.decorate_collection(@results)
    @page_name = "your_businesses"

    render "businesses/index"
  end

  def team_businesses
    @search = SearchParams.new({ "case_owner" => "my_team",
                                 "case_status" => "open_only",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => "team_businesses" })
    @results = search_for_businesses(20)
    @count = @results.total_count
    @businesses = BusinessDecorator.decorate_collection(@results)
    @page_name = "team_businesses"

    render "businesses/index"
  end

private

  def update_business
    @business.assign_attributes(business_params)
    defaults_on_primary_location(@business) if @business.locations.any?
  end

  def set_last_business_view_cookie
    cookies[:last_business_view] = params[:action]
  end

  def set_sort_by_items
    params[:sort_by] = SortByHelper::SORT_BY_RELEVANT if params[:sort_by].blank? && params[:q].present?
    params[:sort_by] = nil if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT && params[:q].blank?

    @sort_by_items = sort_by_items
    @selected_sort_by = params[:sort_by].presence || SortByHelper::SORT_BY_UPDATED_AT
    @selected_sort_direction = params[:sort_dir]
  end

  def sort_by_items
    items = [
      SortByHelper::SortByItem.new("Newly added", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_DEFAULT),
      SortByHelper::SortByItem.new("Name A–Z", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_ASC),
      SortByHelper::SortByItem.new("Name Z–A", SortByHelper::SORT_BY_NAME, SortByHelper::SORT_DIRECTION_DESC)
    ]
    items.unshift(SortByHelper::SortByItem.new("Relevance", SortByHelper::SORT_BY_RELEVANT, SortByHelper::SORT_DIRECTION_DEFAULT)) if params[:q].present?
    items
  end

  def count_to_display
    params[:q].blank? ? Business.count : @results.total_count
  end
end
