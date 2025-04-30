class HelpController < ApplicationController
  skip_before_action :authenticate_user!,
                     :has_accepted_declaration,
                     :has_viewed_introduction,
                     :require_secondary_authentication

  def terms_and_conditions; end

  def privacy_notice; end

  def about
    @taxonomy_export_file_path = taxonomy_export_file_path
  end

  def accessibility; end

  def cookies_policy; end

  def hide_nav?
    !(current_user.present? && current_user.has_accepted_declaration)
  end

private

  def taxonomy_export_file_path
    latest_product_taxonomy_import = ProductTaxonomyImport.completed.last
    latest_file = latest_product_taxonomy_import&.export_file

    if latest_file.present?
      Rails.application.routes.url_helpers.rails_storage_proxy_path(latest_file, only_path: true)
    else
      "#"
    end
  end
end
