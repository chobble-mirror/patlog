require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = User.new(
        name: "Test User",
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
      expect(user).to be_valid
    end

    it "requires a name" do
      user = User.new(email: "test@example.com", password: "password", password_confirmation: "password")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "requires an email" do
      user = User.new(name: "Test User", password: "password", password_confirmation: "password")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a valid email format" do
      user = User.new(
        name: "Test User",
        email: "invalid-email",
        password: "password",
        password_confirmation: "password"
      )
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires a password" do
      user = User.new(name: "Test User", email: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "requires a password of at least 6 characters" do
      user = User.new(
        name: "Test User",
        email: "test@example.com",
        password: "short",
        password_confirmation: "short"
      )
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end

    it "requires a unique email" do
      # Create a user with a specific email
      User.create!(
        name: "First User",
        email: "duplicate@example.com",
        password: "password",
        password_confirmation: "password"
      )

      # Try to create another user with the same email
      duplicate_user = User.new(
        name: "Second User",
        email: "duplicate@example.com",
        password: "password",
        password_confirmation: "password"
      )

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many inspections" do
      user = User.reflect_on_association(:inspections)
      expect(user.macro).to eq(:has_many)
    end

    it "has dependent destroy on inspections" do
      user = User.reflect_on_association(:inspections)
      expect(user.options[:dependent]).to eq(:destroy)
    end
  end
  
  describe "admin functionality" do
    it "sets the first user as admin" do
      # Make sure there are no users
      User.destroy_all
      
      # Create the first user
      first_user = User.create!(
        name: "Admin User",
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password"
      )
      
      # Create a second user
      second_user = User.create!(
        name: "Regular User",
        email: "regular@example.com",
        password: "password",
        password_confirmation: "password"
      )
      
      # Verify the first user is an admin
      expect(first_user.admin?).to be true
      
      # Verify the second user is not an admin
      expect(second_user.admin?).to be false
    end
  end

  describe "inspection_limit" do
    it "defaults to 10" do
      user = User.new(
        name: "Test User",
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
      expect(user.inspection_limit).to eq(10)
    end

    it "validates that inspection_limit is a non-negative integer" do
      user = User.new(
        name: "Test User",
        email: "test@example.com",
        password: "password",
        password_confirmation: "password",
        inspection_limit: -1
      )
      expect(user).not_to be_valid
      expect(user.errors[:inspection_limit]).to include("must be greater than or equal to 0")
    end

    describe "#can_create_inspection?" do
      it "returns true when user has fewer inspections than their limit" do
        user = User.create!(
          name: "Test User",
          email: "test@example.com",
          password: "password",
          password_confirmation: "password",
          inspection_limit: 2
        )
        user.inspections.create!(
          inspector: "John Doe", 
          serial: "PAT-123", 
          description: "Test Description", 
          location: "Test Location",
          earth_ohms: 1.0,
          insulation_mohms: 1.0,
          leakage: 1.0,
          equipment_class: 1,
          fuse_rating: 5
        )
        expect(user.can_create_inspection?).to be true
      end

      it "returns false when user has reached their inspection limit" do
        user = User.create!(
          name: "Test User",
          email: "test@example.com",
          password: "password",
          password_confirmation: "password",
          inspection_limit: 1
        )
        user.inspections.create!(
          inspector: "John Doe", 
          serial: "PAT-123", 
          description: "Test Description", 
          location: "Test Location",
          earth_ohms: 1.0,
          insulation_mohms: 1.0,
          leakage: 1.0,
          equipment_class: 1,
          fuse_rating: 5
        )
        expect(user.can_create_inspection?).to be false
      end
    end
  end
end