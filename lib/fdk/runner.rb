# Looks for call(context, input) function
# Executes it with input
# Responds with output

require 'json'
require 'yajl'

module FDK
  def self.handle(function)
    format = ENV['FN_FORMAT']
    if format == 'cloudevent'
      parser = Yajl::Parser.new

      parser.on_parse_complete = lambda do |event|
        context = Context.new(event)
        body = event['data']
        # Skipping json parsing of body because it would already be a parsed map according to the format spec defined here: https://github.com/cloudevents/spec/blob/master/serialization.md#json
        se = FDK.single_event(function: function, context: context, input: body)

        # Respond with modified event
        event['data'] = se
        event['extensions']['protocol'] = {
          headers: {
              'Content-Type' => ['application/json']
          },
          'status_code' => 200
        }
        $stdout.puts event.to_json
        $stdout.puts
        $stdout.flush
      end

      $stdin.each_line { |line| parser.parse_chunk(line) }

    elsif format == 'json'
      parser = Yajl::Parser.new

      parser.on_parse_complete = lambda do |event|
        context = Context.new(event)
        body = event['body']
        if context.content_type == 'application/json' && body != ''
          body = Yajl::Parser.parse(body)
        end
        se = FDK.single_event(function: function, context: context, input: body)
        response = {
          headers: {
            'Content-Type' => ['application/json']
          },
          'status_code' => 200,
          body: se.to_json
        }
        $stdout.puts response.to_json
        $stdout.puts
        $stdout.flush
      end

      $stdin.each_line { |line| parser.parse_chunk(line) }

    elsif format == 'default'
      event = {}
      event['call_id'] = ENV['FN_CALL_ID']
      event['protocol'] = {
        'type' => 'http',
        'request_url' => ENV['FN_REQUEST_URL']
      }
      $stdout.puts FDK.single_event(function: function, context: Context.new(event), input: $stdin.read).to_json
    else
      raise "Format '#{format}' not supported in Ruby FDK."
    end
  end

  def self.single_event(function:, context:, input:)
    send function, context, input
  end
end
