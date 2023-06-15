class LocationsController < ApplicationController
  include CountriesHelper

  before_action :set_location, only: %i[show edit update remove destroy]
  before_action :create_location, only: %i[create]
  before_action :assign_business, only: %i[show edit update remove create]
  before_action :set_countries, only: %i[create update new edit]
  before_action :set_business_breadcrumbs, only: %i[new show edit remove]

  def show; end

  def new
    @business = Business.find(params[:business_id])
    @location = @business.locations.build
  end

  def edit; end

  def create
    if @location.save
      redirect_to business_url(@location.business, anchor: "locations"), flash: { success: "Location was successfully created." }
    else
      render :new
    end
  end

  def update
    if @location.update(location_params)
      redirect_to business_url(@location.business, anchor: "locations"), flash: { success: "Location was successfully updated." }
    else
      render :edit
    end
  end

  def remove; end

  def destroy
    @location.destroy!
    redirect_to business_url(@location.business, anchor: "locations"), flash: { success: "Location was successfully deleted." }
  end

private

  def assign_business
    @business = @location.business
  end

  def create_location
    business = Business.find(params[:business_id])
    @location = business.locations.create!(location_params.merge({ added_by_user: current_user }))
  end

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:business_id, :name, :address_line_1, :address_line_2, :phone_number, :city, :country, :postal_code)
  end
end
