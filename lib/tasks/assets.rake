namespace :assets do
  desc "Downloads the latest shared OPSS stylesheets"
  task sync_opss_styles: :environment do
    base_uri = "https://raw.githubusercontent.com/OfficeForProductSafetyAndStandards/product-safety-database-prototypes/master/app/assets/sass/opss/"
    stylesheets = ["_opss-pagination.scss", "_opss-psd.scss", "_opss-search.scss", "_opss-shared.scss"]

    stylesheets.each do |stylesheet|
      source_url = URI.join(base_uri, stylesheet).to_s
      destination_file = Rails.root.join("app/assets/stylesheets/opss/", stylesheet).to_s
      system "wget -O #{destination_file} #{source_url}"
    end

    psd_stylesheet = Rails.root.join("app/assets/stylesheets/opss/_opss-psd.scss").to_s
    `mv #{psd_stylesheet} #{psd_stylesheet}.bak; sed 's/@import "opss\\\//@import ".\\\//' #{psd_stylesheet}.bak > #{psd_stylesheet}; rm #{psd_stylesheet}.bak`
  end
end
