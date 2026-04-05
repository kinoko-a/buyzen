class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # :validatableで下記の検証ルールを設定済み
  # email: presence, uniqueness, format(email_regexp)
  # password & password_confirmation: presence, length(6..128)

  validates :name, presence: true, length: { maximum: 30 }
  validates :password, format: { with: /\A(?=.*[a-zA-Z])(?=.*\d).+\z/,
                       message: "は英数字を混ぜて入力してください" }

  has_many :items, dependent: :destroy
  has_many :questions, dependent: :destroy
end
