Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end

if defined?(WillPaginate)
  module WillPaginate
    module ActiveRecord
      module RelationMethods
        def per(value = nil) per_page(value) end

        def total_count() count end

        def first_page?() self == first end

        def last_page?() self == last end
      end
    end
    module CollectionMethods
      alias_method :num_pages, :total_pages
    end
  end
end

RailsAdmin.config do |config|
  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    show
    edit

    # export
    # bulk_delete
    # delete
    # show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.model "User" do
    list do
      field :name
      field :email
      field :created_at
    end
    show do
      field :name
      field :email
      field :has_accepted_declaration
      field :mobile_number_verified
      field :sign_in_count
    end
    edit do
      field :mobile_number
      field :name
    end
  end

  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.authorize_with do |_controller|
    if !current_user.is_superuser?
      redirect_to main_app.unauthenticated_root_path
    end
  end

  config.included_models = %w[User]
end
