class ContactsController < ApplicationController
  include BreadcrumbHelper

  before_action :set_contact, only: %i[edit update remove destroy]
  before_action :create_contact, only: %i[create]
  before_action :assign_business, only: %i[edit remove]
  before_action :set_breadcrumb, only: %i[new edit remove]

  def new
    @business = Business.find(params[:business_id])
    @contact = @business.contacts.build
  end

  def edit; end

  def create
    if @contact.save
      redirect_to business_url(@contact.business, anchor: "contacts"), flash: { success: "Contact was successfully created." }
    else
      render :new
    end
  end

  def update
    if @contact.update(contact_params)
      redirect_to business_url(@contact.business, anchor: "contacts"), flash: { success: "Contact was successfully updated." }
    else
      render :edit
    end
  end

  def remove; end

  def destroy
    @contact.destroy!
    redirect_to business_url(@contact.business, anchor: "contacts"), flash: { success: "Contact was successfully deleted." }
  end

private

  def assign_business
    @business = @contact.business
  end

  def create_contact
    business = Business.find(params[:business_id])
    @contact = business.contacts.create!(contact_params.merge({ added_by_user: current_user }))
  end

  def set_breadcrumb
    breadcrumb "businesses.label", :businesses_path
    breadcrumb breadcrumb_business_label, breadcrumb_business_path
    breadcrumb @business.trading_name, business_path(@business) if @business&.persisted?
  end

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:business_id, :name, :email, :phone_number, :job_title)
  end
end
