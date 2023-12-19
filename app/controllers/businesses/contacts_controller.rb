module Businesses
  class ContactsController < ApplicationController
    before_action :set_business
    before_action :set_contact, except: %i[new create]
    before_action :set_business_breadcrumbs, only: %i[new edit remove]

    def new
      @contact = @business.contacts.build
      breadcrumb @business.trading_name, business_path(@business)
    end

    def edit; end

    def create
      @contact = @business.contacts.create!(contact_params.merge({ added_by_user: current_user }))
      if @contact.save
        redirect_to business_url(@business, anchor: "contacts"), flash: { success: "Contact was successfully created." }
      else
        render :new
      end
    end

    def update
      if @contact.update(contact_params)
        redirect_to business_url(@business, anchor: "contacts"), flash: { success: "Contact was successfully updated." }
      else
        render :edit
      end
    end

    def remove; end

    def destroy
      @contact.destroy!
      redirect_to business_url(@business, anchor: "contacts"), flash: { success: "Contact was successfully deleted." }
    end

  private

    def set_business
      @business = Business.find(params[:business_id])
    end

    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(:business_id, :name, :email, :phone_number, :job_title)
    end
  end
end
