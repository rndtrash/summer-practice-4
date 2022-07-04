require "uuid"
require "redis"
require "../config"

abstract class Application < ActionController::Base
  # Configure your log source name
  # NOTE:: this is chaining from App::Log
  Log = ::App::Log.for("controller")

  before_action :set_request_id
  before_action :set_date_header

  after_action :set_codepage

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id

    # If this is an upstream service, the ID should be extracted from a request header.
    # request_id = request.headers["X-Request-ID"]? || UUID.random.to_s
    # Log.context.set client_ip: client_ip, request_id: request_id
    # response.headers["X-Request-ID"] = request_id
  end

  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end

  def set_codepage
    unless response.headers["Content-Type"]?.nil?
      response.headers["Content-Type"] += "; charset=utf-8"
    end
  end
end
