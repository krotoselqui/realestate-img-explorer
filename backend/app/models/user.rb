class User < ApplicationRecord
  # パスワードの暗号化
  has_secure_password

  # コールバック
  before_save :downcase_email

  # バリデーション
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  
  validates :username,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 }
  
  validates :profile,
            length: { maximum: 1000 },
            allow_nil: true
  
  validates :password,
            length: { minimum: 6 },
            if: -> { new_record? || changes[:password_digest] }

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
