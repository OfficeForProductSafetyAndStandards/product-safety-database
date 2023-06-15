class LocationsController < ApplicationController
  include CountriesHelper
  include BreadcrumbHelper

  before_action :set_location, only: %i[show edit update remove destroy]
  before_action :create_location, only: %i[create]
  before_action :assign_business, only: %i[show edit update remove create]
  before_action :set_countries, only: %i[create update new edit]
  before_action :set_breadcrumb, only: %i[new show edit remove]

  # GET /locations/1
  # GET /locations/1.json
  def show; end

  # GET /locations/new
  def new
    @business = Business.find(params[:business_id])
    @location = @business.locations.build
  end

  # GET /locations/1/edit
  def edit; end

  # POST /locations
  # POST /locations.json
  def create
    respond_to do |format|
      if @location.save
        format.html do
          redirect_to business_url(@location.business, anchor: "locations"),
                      flash: { success: "Location was successfully created." }
        end
        format.json { render :show, status: :created, location: @location }
      else
        format.html { render :new }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /locations/1
  # PATCH/PUT /locations/1.json
  def update
    respond_to do |format|
      if @location.update(location_params)
        format.html do
          redirect_to business_url(@location.business, anchor: "locations"),
                      flash: { success: "Location was successfully updated." }
        end
        format.json { render :show, status: :ok, location: @location }
      else
        format.html { render :edit }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove; end

  # DELETE /locations/1
  # DELETE /locations/1.json
  def destroy
    @location.destroy!
    respond_to do |format|
      format.html do
        redirect_to business_url(@location.business, anchor: "locations"),
                    flash: { success: "Location was successfully deleted." }
      end
      format.json { head :no_content }
    end
  end

private

  def assign_business
    @business = @location.business
  end

  def create_location
    business = Business.find(params[:business_id])
    @location = business.locations.create!(location_params.merge({ added_by_user: current_user }))
  end

  def set_breadcrumb
    breadcrumb "businesses.label", :businesses_path
    breadcrumb breadcrumb_business_label, breadcrumb_business_path
    breadcrumb @business.trading_name, business_path(@business) if @business&.persisted?
  end

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:business_id, :name, :address_line_1, :address_line_2, :phone_number, :city, :country, :postal_code)
  end
end
