class BusinessesController < ApplicationController
  include BusinessesHelper
  include UrlHelper
  include CountriesHelper
  helper_method :sort_column, :sort_direction

  before_action :set_search_params, only: %i[index]
  before_action :set_business, only: %i[show edit update]
  before_action :update_business, only: %i[update]
  before_action :build_breadcrumbs, only: %i[show]
  before_action :set_countries, only: %i[update edit]

  # GET /businesses
  # GET /businesses.json
  def index
    respond_to do |format|
      format.html do
        results = search_for_businesses(20)
        @businesses = BusinessDecorator.decorate_collection(results)
      end
      format.csv do
        authorize Business, :export?

        results = search_for_businesses.records.includes(:investigations, :locations, :contacts)
        @businesses = BusinessDecorator.decorate_collection(results)

        render csv: @businesses, filename: "businesses"
      end
    end
  end

  def new
    @investigation = Investigation.find_by(id: params["investigation_id"]).decorate
    @business_form = BusinessForm.new
  end

  def create
    @business_form = BusinessForm.new(business_form_attributes)
    @investigation = Investigation.find_by(id: params["investigation_id"])

    if @business_form.valid?
      CreateBusiness.call!(
        @business_form.serializable_hash.except(:investigation_id).merge(user: current_user)
      )
    end

    if @investigation
      redirect_to new_business_relationship_path(business_id: Business.last.id, investigation_pretty_id: @investigation.pretty_id)
    else
      redirect_to businesses_path
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

  def business_form_attributes
    params.require(:business_form).permit(:trading_name, :legal_name, :company_number)
  end

  def update_business
    @business.assign_attributes(business_params)
    defaults_on_primary_location(@business) if @business.locations.any?
  end

  def build_breadcrumbs
    @breadcrumbs = build_back_link_to_case || build_breadcrumb_structure
  end
end
