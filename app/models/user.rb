class User < ApplicationRecord
  def inspect
    "#<User id: #{id}, email: #{email}, migrated_to_devise: #{migrated_to_devise}>"
  end
  # Include only what we need from Devise
  devise :database_authenticatable, :validatable

  # Don't include has_secure_password when Devise is present
  # We'll handle legacy passwords manually
  
  # Your existing associations
  has_many :categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :monthly_reviews, dependent: :destroy
  has_many :monthly_category_reviews, through: :monthly_reviews

  # Your existing validations
  validates :email, presence: true, uniqueness: true
  validates :hourly_wage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_create :create_default_categories

  # Override password requirement during transition
  def password_required?
    return false if persisted? && !migrated_to_devise?
    super
  end

  # Migrate user from has_secure_password to Devise
  def migrate_to_devise!(plain_password)
    return true if migrated_to_devise?
    
    self.password = plain_password
    self.password_confirmation = plain_password
    self.migrated_to_devise = true
    
    if save(validate: false)
      Rails.logger.info "Successfully migrated user #{email} to Devise"
      true
    else
      Rails.logger.error "Failed to migrate user #{email} to Devise: #{errors.full_messages.join(', ')}"
      false
    end
  end

  # Helper method to check legacy password
  def valid_legacy_password?(password)
    return false if migrated_to_devise?
    password_digest = read_attribute(:password_digest)
    return false unless password_digest
    
    BCrypt::Password.new(password_digest).is_password?(password)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  private

  def create_default_categories
    default_category_names = ["Housing", "Food", "Transportation", "Utilities", "Insurance", 
                              "Healthcare", "Savings", "Debt", "Personal", "Entertainment", "Taxes"]
    default_category_names.each do |name|
      categories.create!(name: name, is_default: true)
    end
  end
end