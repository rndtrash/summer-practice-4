require "cryomongo"
require "uri"

require "../constants.cr"
require "../models/user.cr"

class API < Application
  base "/api"

  rescue_from NilAssertionError do |_error|
    render :bad_request, json: {"status": "error"}
  end

  rescue_from Mongo::Error::CommandWrite do |_error|
    render :bad_request, json: {"status": "error"}
  end

  class NewUserParams < ActiveModel::Model
    attribute last_name : String
    attribute first_name : String
    attribute middle_name : String?

    attribute phone_number : String
    attribute email : String
    attribute login : String
    attribute password : String
  end

  get "/user/new", :new_user do
    p = NewUserParams.from_json(request.body.not_nil!).not_nil!

    u = User.new(last_name: p.last_name, first_name: p.first_name, middle_name: p.middle_name, phone_number: p.phone_number, email: p.email, login: p.login)
    render :bad_request, json: {"status": "error"} unless u.set_password(p.password) && u.valid?
    u.insert

    render json: {"status": "ok"}
  end
end
