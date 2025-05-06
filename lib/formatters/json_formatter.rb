module Formatters
  class JsonFormatter < ::Logger::Formatter
    def call(_severity, _time, _progname, msg)
      # Output only the message (which should be JSON) without Rails logger prefix
      # This removes the "I, [2025-04-30T13:55:43.349479 #1] INFO -- : [905c0821-f6ac-431e-8e46-0a55d862e2b4]" prefix
      "#{msg}\n"
    end
  end
end
