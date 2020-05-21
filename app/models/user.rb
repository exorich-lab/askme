# frozen_string_literal: true

# Эта библиотека для шифрования
require 'openssl'

class User < ApplicationRecord
  # Параметры работы для модуля шифрования паролей
  ITERATIONS = 20_000
  DIGEST = OpenSSL::Digest::SHA256.new

  # Перед сохранением объекта в базу, создаем зашифрованный пароль, который
  # будет хранится в БД.
  before_save :encrypt_password

  before_create { username.downcase! }

  def encrypt_password
    if password.present?
      # Создаем т.н. «соль» — случайная строка, усложняющая задачу хакерам по
      # взлому пароля, даже если у них окажется наша БД.
      # У каждого юзера своя «соль», это значит, что если подобрать перебором пароль
      # одного юзера, нельзя разгадать, по какому принципу
      # зашифрованы пароли остальных пользователей
      self.password_salt = User.hash_to_string(OpenSSL::Random.random_bytes(16))

      # Создаем хэш пароля — длинная уникальная строка, из которой невозможно
      # восстановить исходный пароль. Однако, если правильный пароль у нас есть,
      # мы легко можем получить такую же строку и сравнить её с той, что в базе.
      self.password_hash = User.hash_to_string(
        OpenSSL::PKCS5.pbkdf2_hmac(
          password, password_salt, ITERATIONS, DIGEST.length, DIGEST
        )
      )

      # Оба поля попадут в базу при сохранении (save).
    end
  end

  # Служебный метод, преобразующий бинарную строку в шестнадцатиричный формат,
  # для удобства хранения.
  def self.hash_to_string(password_hash)
    password_hash.unpack1('H*')
  end

  # Основной метод для аутентификации юзера (логина). Проверяет email и пароль,
  # если пользователь с такой комбинацией есть в базе, возвращает этого
  # пользователя. Если нет — возвращает nil.
  def self.authenticate(email, password)
    # Сперва находим кандидата по email
    user = find_by(email: email)

    # Если пользователь не найден, возвращает nil
    return nil unless user.present?

    # Формируем хэш пароля из того, что передали в метод
    hashed_password = User.hash_to_string(
      OpenSSL::PKCS5.pbkdf2_hmac(
        password, user.password_salt, ITERATIONS, DIGEST.length, DIGEST
      )
    )

    # Обратите внимание: сравнивается password_hash, а оригинальный пароль так
    # никогда и не сохраняется нигде. Если пароли совпали, возвращаем
    # пользователя.
    return user if user.password_hash == hashed_password

    # Иначе, возвращаем nil
    nil
  end

  # Виртуальное поле, которое не сохраняется в базу. Из него перед сохранением
  # читается пароль, и сохраняется в базу уже зашифрованная версия пароля в
  attr_accessor :password

  # валидация будет проходить только при создании нового юзера
  validates :password, presence: true, on: :create

  # и поле подтверждения пароля
  validates_confirmation_of :password

  # Валидация, которая проверяет, что поля email и username не пустые и не равны
  # nil. Если не задан email и username, объект не будет сохранен в базу.
  validates :email, :username, presence: true

  # Когда мы вызываем метод questions у экземпляра класса User, рельсы
  # поймут это как просьбу найти в базе все объекты класса Questions со
  # значением user_id равный user.id.
  has_many :questions, dependent: :destroy

  # Валидация на уникальность username без учета регистра.
  validates :email, :username, uniqueness: { case_sensitive: false }

  # Валидация, которая проверяет, что поле email заполненно в верном формате
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Валидация, которая проверяет, что username содержит не менее
  # 3 и не более 40 символов
  validates :username, length: { minimum: 3, maximum: 40 }

  # Валидация, которая проверяет, что username содержит буквы цифры и _
  validates :username, format: { with: /\A[a-z\d_]*\z/i,
                                 message: "only allows letters, digits, and '_'" }
end
