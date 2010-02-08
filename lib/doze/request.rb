require 'doze/error'
require 'doze/utils'

# Some helpers for Rack::Request
class Doze::Request < Rack::Request
  def initialize(app, env)
    @app = app
    super(env)
  end

  attr_reader :app

  # this delibarately ignores the HEAD vs GET distinction; use head? to check
  def normalized_request_method
    method = @env["REQUEST_METHOD"]
    method == 'HEAD' ? 'get' : method.downcase
  end

  def get_or_head?
    method = @env["REQUEST_METHOD"]
    method == "GET" || method == "HEAD"
  end

  def options?
    @env["REQUEST_METHOD"] == 'OPTIONS'
  end

  def entity
    return @entity if defined?(@entity)
    @entity = if media_type
      media_type.new_entity(
        :binary_data_stream => env['rack.input'],
        :binary_data_length => content_length && content_length.to_i,
        :encoding           => content_charset,
        :media_type_params  => media_type_params
      )
    end
  end

  def media_type
    @mt ||= (mt = super and Doze::MediaType[mt])
  end

  # For now, to do authentication you need some (rack) middleware that sets one of these env's.
  # See :session_from_rack_env under Doze::Application config
  def session
    @session ||= @app.config[:session_from_rack_env].call(@env)
  end

  def session_authenticated?
    @session_authenticated ||= (session && @app.config[:session_authenticated].call(session))
  end
end
