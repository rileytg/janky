module Janky
  module Exception
    def self.setup(notifier)
      @notifier = notifier
    end

    def self.report(exception, context={})
      @notifier.report(exception, context)
    end

    def self.push(context)
      @notifier.push(context)
    end

    def self.reset!
      @notifier.reset!
    end

    def self.push_http_response(response)
      push(
        :response_code => response.code.inspect,
        :response_body => response.body.inspect
      )
    end

    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        Exception.reset!
        Exception.push(
          :app          => "janky",
          :method       => request.request_method,
          :user_agent   => request.user_agent,
          :params       => (request.params.inspect rescue nil),
          :session      => (request.session.inspect rescue nil),
          :referrer     => request.referrer,
          :remote_ip    => request.ip,
          :url          => request.url
        )
        @app.call(env)
      rescue Object => boom
        Exception.report(boom)
        raise
      end
    end

    class Logger
      def initialize(stream)
        @stream = stream
        @context = {}
      end

      def reset!
        @context = {}
      end

      def report(e, context={})
        @stream.puts "ERROR: #{e.class} - #{e.message}\n"
        @context.each do |k, v|
          @stream.puts "%12s %4s\n" % [k, v]
        end
        @stream.puts "\n#{e.backtrace.join("\n")}"
      end

      def push(context)
        @context.update(context)
      end
    end

    class Mock
      def self.push(context)
      end

      def self.report(e, context={})
      end

      def self.reset!
      end
    end
  end
end
