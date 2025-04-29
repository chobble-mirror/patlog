class User < ApplicationRecord
  has_secure_password
  has_many :inspections, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, presence: true, length: {minimum: 6}, if: :password_digest_changed?
  validates :inspection_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  before_create :set_admin_if_first_user
  
  def can_create_inspection?
    inspections.count < inspection_limit
  end
  
  private
  
  def set_admin_if_first_user
    self.admin = User.count.zero?
  end
end
