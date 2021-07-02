# frozen_string_literal: true

module ActiveWebhook
  class Logger
    def info(msg)
      puts msg
    end

    def debug(msg)
      puts msg
    end

    def error(msg)
      puts msg
    end

    def warn(msg)
      puts msg
    end
  end
end
