require "cryomongo"
require "uri"

require "../constants.cr"
require "../models/user.cr"

class API < Application
  base "/api"

  rescue_from NilAssertionError do |_error|
    render :bad_request, json: {"status": "error"}
  end

  rescue_from KeyError do |_error|
    render :bad_request, json: {"status": "error"}
  end

  rescue_from Mongo::Error::CommandWrite do |_error|
    render :bad_request, json: {"status": "error"}
  end

  class UserParams < ActiveModel::Model
    attribute last_name : String
    attribute first_name : String
    attribute middle_name : String?

    attribute phone_number : String
    attribute email : String
    attribute login : String
    attribute password : String
  end

  get "/user", :get_user do
    u = User.find_one({ login: params["login"] })

    render :bad_request, json: { "status": "error" } if u.nil?

    render json: u.to_frontend_json
  end

  get "/user/new", :new_user do
    p = UserParams.from_json(request.body.not_nil!).not_nil!

    u = User.new(last_name: p.last_name, first_name: p.first_name, middle_name: p.middle_name, phone_number: p.phone_number, email: p.email, login: p.login)
    render :bad_request, json: {"status": "error"} unless u.set_password(p.password) && u.valid?

    u.insert

    render json: {"status": "ok"}
  end

  get "/user/update", :update_user do
    p = UserParams.from_json(request.body.not_nil!).not_nil!

    render :bad_request, json: {"status": "error"} if App::REGEX_LOGIN.match(p.login).nil?

    u = User.find_one({login: p.login}).not_nil!

    render :bad_request, json: {"status": "error"} unless u.correct_password?(p.password)

    u.last_name = p.last_name
    u.first_name = p.first_name
    u.middle_name = p.middle_name
    u.phone_number = p.phone_number
    u.email = p.email
    u.login = p.login

    render :bad_request, json: {"status": "error"} unless u.valid?

    u.update

    render json: {"status": "ok"}
  end

  get "/user/delete", :delete_user do
    render :bad_request, json: {"status": "error"} if App::REGEX_LOGIN.match(params["login"].not_nil!).nil?

    u = User.find_one({login: params["login"].not_nil!}).not_nil!

    render :bad_request, json: {"status": "error"} unless u.correct_password?(params["password"].not_nil!)

    u.remove

    render json: {"status": "ok"}
  end

  post "/import", :import_users do
    User.collection.delete_many(filter: {} of String => String) unless params["overwrite"]?.nil?

    accepted = rejected = 0
    request.body.not_nil!.each_line do |line|
      u = User.from_csv(line)
      if u.nil?
        rejected += 1
      else
        accepted += 1
      end
    end

    render json: {"status": "ok", "accepted": accepted, "rejected": rejected}
  end

  get "/export", :export_users do
    result = ""

    User.find().each do |u|
      result += u.to_csv + '\n'
    end

    render text: result
  end
end
