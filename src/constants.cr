require "action-controller/logger"
require "secrets-env"
require "random"
require "regex"

module App
  NAME    = "Summer Practice 4"
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}

  MONGODB_URI = ENV["SP4_MONGODB_URI"]? || "mongodb://localhost:27017"
  MONGODB_DB  = ENV["SP4_MONGODB_DB"]? || "sp4"

  Log         = ::Log.for(NAME)
  LOG_BACKEND = ActionController.default_backend

  ENVIRONMENT = ENV["SG_ENV"]? || "development"

  DEFAULT_PORT          = (ENV["SG_SERVER_PORT"]? || 3000).to_i
  DEFAULT_HOST          = ENV["SG_SERVER_HOST"]? || "127.0.0.1"
  DEFAULT_PROCESS_COUNT = (ENV["SG_PROCESS_COUNT"]? || 1).to_i

  STATIC_FILE_PATH = ENV["PUBLIC_WWW_PATH"]? || "./www"

  COOKIE_SESSION_KEY    = ENV["COOKIE_SESSION_KEY"]? || "_sp4_"
  COOKIE_SESSION_SECRET = ENV["COOKIE_SESSION_SECRET"]? || Random::Secure.hex

  REGEX_LAST_MIDDLE_NAME = /^[А-ЯЁ][а-яё]+(-[А-ЯЁ][а-яё]+)?$/
  REGEX_FIRST_NAME       = /^[А-ЯЁ][а-яё]+(-[а-яё]+)?$/
  REGEX_PHONE_NUMBER     = /^\+7-\([0-9]{3}\)-[0-9]{3}(-[0-9]{2}){2}$/
  REGEX_EMAIL            = /^[A-Za-z0-9.+\-_]+@([a-z0-9]+\.)+([a-z])+$/
  REGEX_LOGIN            = /^[A-Za-z0-9.\-_]+$/

  def self.running_in_production?
    ENVIRONMENT == "production"
  end
end
