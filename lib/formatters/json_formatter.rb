module Formatters
  class JsonFormatter < ::Logger::Formatter
    def call(_severity, _time, _progname, msg)
      # Remove any request ID prefix from the message
      msg = msg.gsub(/^\[[^\]]+\]\s*/, "")
      # Output only the message (which should be JSON) without Rails logger prefix
      "#{msg}\n"
    end
  end
end
