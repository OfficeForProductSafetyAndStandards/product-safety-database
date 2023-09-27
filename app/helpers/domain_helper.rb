module DomainHelper
  def www_domain_url
    root_url(host: ENV["PSD_HOST"])
  end

  def support_domain_url
    root_url(host: ENV["PSD_HOST_SUPPORT"])
  end
end
