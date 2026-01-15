# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  username               :string           not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :dreams, dependent: :destroy
  has_many :tags, dependent: :destroy

  validates :username, presence: true, uniqueness: true

  # NOTE: authentication_keys=[:login]だが、Devise内部で:emailキーを使うこともあるため両方対応
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:email) || conditions.delete(:login)

    return find_by(conditions) unless login

    # NOTE: case_insensitive_keys=[]によりセキュリティ・データ一貫性を優先（完全一致）
    where(conditions).find_by(['email = :value OR username = :value', { value: login }])
  end
end
