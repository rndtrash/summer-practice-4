require "moongoon"
require "blake3"
require "regex"
require "json"
require "bson"

require "../constants.cr"

class User < Moongoon::Collection
  collection "users"

  index keys: { login: 1 }, options: { unique: true }

  property last_name : String # Фамилия
  property first_name : String # Имя
  property middle_name : String? # Отчество (его может и не быть!)

  property phone_number : String # Номер телефона. Формат: +7-(xxx)-xxx-xx-xx
  property email : String # Электронная почта. Формат: [A-Za-z0-9.+\-_]+@([a-z0-9]+\.)+[a-z]+
  property login : String # Логин. Формат: [A-Za-z0-9.\-_]

  property password_hash : String = ""

  def set_password(password : String) : Bool
    # Требования к паролю:
    # * не короче 8 символов
    # * как минимум одна заглавная буква
    # * как минимум одна строчная буква
    # * как минимум одна цифра
    # * как минимум один специальный символ
    return false if password.bytesize < 8 || /[A-ZА-ЯЁ]/.match(password).nil? || /[a-zа-яё]/.match(password).nil? || /[0-9]/.match(password).nil? || /[!@#$%^&*()_+\-=]/.match(password).nil?

    digest = Digest::Blake3.new
    digest.update password
    @password_hash = digest.final.hexstring

    true
  end

  def correct_password?(password : String) : Bool
    digest = Digest::Blake3.new
    digest.update password

    @password_hash == digest.final.hexstring
  end

  def valid? : Bool
    # Валидация ФИО
    return false if App::REGEX_LAST_MIDDLE_NAME.match(@last_name).nil? || (!@middle_name.nil? && App::REGEX_LAST_MIDDLE_NAME.match(@middle_name.not_nil!).nil?) || App::REGEX_FIRST_NAME.match(@first_name).nil?

    # Валидация номера телефона
    return false if App::REGEX_PHONE_NUMBER.match(@phone_number).nil?

    # Валидация электронной почты
    return false if App::REGEX_EMAIL.match(@email).nil?

    # Валидация логина
    return false if App::REGEX_LOGIN.match(@login).nil?

    # Валидация пароля
    return false unless @password_hash.bytesize == 64

    true
  end

  def send_email(message : String)
    # TODO: выслать e-mail :S
  end

  def self.from_csv(s : String) : User?
    split = s.split(',')
    return nil if split.size != 7

    middle_name : String?
    last_name, first_name, middle_name, phone_number, email, login, password_hash = split
    middle_name = nil if middle_name.size == 0

    u = User.new(last_name: last_name, first_name: first_name, middle_name: middle_name, phone_number: phone_number, email: email, login: login, password_hash: password_hash)
    return nil unless u.valid?

    begin
      u.insert
    rescue ex
      Log.debug { ex.message }
      return nil
    end

    u
  end

  def to_csv : String
    "#{@last_name},#{@first_name},#{@middle_name},#{@phone_number},#{@email},#{@login},#{@password_hash}"
  end

  # Функция, выводящая общеизвестную информацию о пользователе. На данный момент бесполезна ибо любой желающий может получить *всю* базу в CSV
  # на блюдечке с голубой каёмочкой
  def to_frontend_json
    {
      last_name: @last_name,
      first_name: @first_name,
      middle_name: @middle_name,

      phone_number: @phone_number,
      email: @email,
      login: @login
    }
  end
end
