# frozen_string_literal: true

class AddUserToQuestion < ActiveRecord::Migration[6.0]
  def change
    add_reference :questions, :user, foreign_key: true
  end
end
