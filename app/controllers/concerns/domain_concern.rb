module DomainConcern
  extend ActiveSupport::Concern

  def main_domain?
    main_domain == request.host
  end

  def support_domain?
    support_domain == request.host
  end

  def report_domain?
    report_domain == request.host
  end

  included do
    helper_method :main_domain?
    helper_method :support_domain?
    helper_method :report_domain?
  end

private

  def main_domain
    ENV["PSD_HOST"]
  end

  def support_domain
    ENV["PSD_HOST_SUPPORT"]
  end

  def report_domain
    ENV["PSD_HOST_REPORT"]
  end
end
