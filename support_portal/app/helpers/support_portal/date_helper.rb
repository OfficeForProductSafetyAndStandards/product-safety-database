module SupportPortal
  module DateHelper
    def display_date(date)
      date&.strftime("%d/%m/%Y")
    end

    def display_time(date)
      date&.strftime("%H:%M:%S")
    end

    def display_date_time(date)
      date = Time.zone.parse(date) if date.is_a?(String)
      date&.strftime("%d/%m/%Y %H:%M")
    end
  end
end
