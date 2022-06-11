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

    attribute new_password : String?
  end

  get "/user", :get_user do
    unless params["login"]?.nil?
      u = User.find_one({ login: params["login"] })

      render :bad_request, json: { "status": "error" } if u.nil?

      render json: u.to_frontend_json
    end

    q = {} of String => (String | Nil | Hash(String, Int32))
    unless params["last_name"]?.nil?
      q["last_name"] = params["last_name"]
    end
    unless params["first_name"]?.nil?
      q["first_name"] = params["first_name"]
    end
    unless params["middle_name"]?.nil?
      q["middle_name"] = params["middle_name"].bytesize == 0 ? nil : params["middle_name"]
    end
    unless params["phone_number"]?.nil?
      q["phone_number"] = params["phone_number"]
    end

    sort = Hash(String, Int32).new
    unless params["sort"]?.nil?
      sortable_columns = {"last_name": nil, "first_name": nil, "middle_name": nil, "phone_number": nil, "email": nil, "login": nil}
      render :bad_request, json: { "status": "error" } unless sortable_columns.has_key?(params["sort"])
      sort[params["sort"]] = params["reverse"]?.nil? ? 1 : -1
    end

    us = User.find(q, order_by: sort)
    render :bad_request, json: { "status": "error" } if us.nil? || us.size == 0

#    result = ""

#    us.each do |u|
#      result += u.to_csv + '\n'
#    end

#    render text: result
    result = Array({
      last_name: String,
      first_name: String,
      middle_name: String?,

      phone_number: String,
      email: String,
      login: String
    }).new

    us.each do |u|
      result.push u.to_frontend_json
    end

    render json: result
  end

  post "/user/new", :new_user do
    p = UserParams.from_json(request.body.not_nil!).not_nil!

    u = User.new(last_name: p.last_name, first_name: p.first_name, middle_name: p.middle_name, phone_number: p.phone_number, email: p.email, login: p.login)
    render :bad_request, json: {"status": "error"} unless u.set_password(p.password) && u.valid?

    u.insert

    render json: {"status": "ok"}
  end

  put "/user/update", :update_user do
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

    render :bad_request, json: {"status": "error"} unless p.new_password.nil? || u.set_password(p.new_password.not_nil!)

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
