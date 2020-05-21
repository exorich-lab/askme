# frozen_string_literal: true

class Question < ApplicationRecord
  # Эта валидация препятствует созданию вопросов, у которых поле text пустое, объект не будет сохранен в базу.
  validates :text, presence: true

  # Эта команда добавляет связь с моделью User на уровне объектов, она же
  # добавляет метод .user к данному объекту.
  #
  # Когда мы вызываем метод user у экземпляра класса Question, рельсы
  # поймут это как просьбу найти в базе объект класса User со значением id,
  # который равен question.user_id.
  belongs_to :user

  # Валидация длинны строки 'text' От 5 символов до 255 текст вопроса.
  validates :text, length: { minimum: 5, maximum: 255 }
end
