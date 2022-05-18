require "moongoon"
require "blake3"
require "regex"

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
    Log.info {"password ok"}

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
    Log.info {"fio ok"}

    # Валидация номера телефона
    return false if App::REGEX_PHONE_NUMBER.match(@phone_number).nil?
    Log.info {"phone ok"}

    # Валидация электронной почты
    return false if App::REGEX_EMAIL.match(@email).nil?
    Log.info {"mail ok"}

    # Валидация логина
    return false if App::REGEX_LOGIN.match(@login).nil?
    Log.info {"login ok"}

    # Валидация пароля
    return false if @password_hash.bytesize == 0
    Log.info {"password hash ok"}

    true
  end

  def send_email(message : String)
    # TODO: выслать e-mail :S
  end

  def from_string(s : String)
    # TODO: сериализация из текстового файла
  end
end
