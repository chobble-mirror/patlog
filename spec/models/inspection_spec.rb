require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }

  describe "validations" do
    it "validates presence of required fields" do
      inspection = Inspection.new(user: user)
      expect(inspection).not_to be_valid
      expect(inspection.errors[:inspector]).to include("can't be blank")
      expect(inspection.errors[:serial]).to include("can't be blank")
      expect(inspection.errors[:description]).to include("can't be blank")
      expect(inspection.errors[:location]).to include("can't be blank")
    end

    it "validates numericality of measurements" do
      inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "TEST123",
        description: "Test Equipment",
        location: "Test Location",
        equipment_class: 1,
        earth_ohms: -1,
        insulation_mohms: 0,
        leakage: -0.1,
        fuse_rating: 13
      )

      expect(inspection).not_to be_valid
      expect(inspection.errors[:earth_ohms]).to include("must be greater than 0")
      expect(inspection.errors[:insulation_mohms]).to include("must be greater than 0")
      expect(inspection.errors[:leakage]).to include("must be greater than 0")
    end

    it "requires a user" do
      inspection = Inspection.new(
        inspector: "Test Inspector",
        serial: "TEST123",
        description: "Test Equipment",
        location: "Test Location",
        equipment_class: 1,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        fuse_rating: 13
      )

      expect(inspection).not_to be_valid
      expect(inspection.errors[:user]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to a user" do
      association = Inspection.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "esoteric tests" do
    # Test with extremely high measurements
    it "handles extremely high measurement values" do
      inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "HIGH123",
        description: "Test Equipment",
        location: "Test Location",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 32,
        earth_ohms: 1_000_000.5,      # Extremely high earth resistance
        insulation_mohms: 9_999_999,  # Extremely high insulation resistance
        leakage: 999.999,             # Extremely high leakage current
        passed: false,
        comments: "Extreme measurements test"
      )

      expect(inspection).to be_valid
    end

    # Test with Unicode characters and emoji in text fields
    it "handles Unicode characters and emoji in text fields" do
      inspection = Inspection.new(
        user: user,
        inspector: "Jörgen Müller 👨‍🔧",
        serial: "ÜNICØDÉ-😎-123",
        description: "💻 MacBook Pro «Special»",
        location: "Meeting Room 🏢 3F",
        equipment_class: 2,
        visual_pass: true,
        fuse_rating: 5,
        earth_ohms: 0.1,
        insulation_mohms: 100,
        leakage: 0.5,
        passed: true,
        comments: "❗️Tested with special 🔌 adapter. Result: ✅"
      )

      expect(inspection).to be_valid
      inspection.save!

      # Retrieve and verify data is intact
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector).to eq("Jörgen Müller 👨‍🔧")
      expect(retrieved.serial).to eq("ÜNICØDÉ-😎-123")
      expect(retrieved.description).to eq("💻 MacBook Pro «Special»")
      expect(retrieved.comments).to eq("❗️Tested with special 🔌 adapter. Result: ✅")
    end

    # Test with maximum possible database field lengths
    it "handles maximum length strings in text fields" do
      extremely_long_text = "A" * 65535  # Text field typical max size

      inspection = Inspection.new(
        user: user,
        inspector: "Max Length Tester",
        serial: "MAX123",
        description: "Max length test",
        location: "Test lab",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true,
        comments: extremely_long_text
      )

      expect(inspection).to be_valid
      inspection.save!

      # Verify the extremely long comment was saved correctly
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.comments).to eq(extremely_long_text)
    end

    # Test with SQL injection attempts in string fields
    it "safely handles strings that look like SQL injection attempts" do
      inspection = Inspection.new(
        user: user,
        inspector: "Robert'); DROP TABLE inspections; --",
        serial: "'; SELECT * FROM users; --",
        description: "Equipment'); DELETE FROM inspections; --",
        location: "Location'); UPDATE users SET admin=true; --",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true,
        comments: "Normal comment"
      )

      expect(inspection).to be_valid
      inspection.save!

      # Verify the data was saved correctly and didn't affect the database
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector).to eq("Robert'); DROP TABLE inspections; --")

      # Verify all inspections still exist
      expect(Inspection.count).to be >= 1
    end

    # Test with boundary values for equipment_class
    it "validates equipment_class must be 1 or 2" do
      valid_inspection1 = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "CLASS1",
        description: "Class 1 Equipment",
        location: "Test Location",
        equipment_class: 1,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2
      )

      valid_inspection2 = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "CLASS2",
        description: "Class 2 Equipment",
        location: "Test Location",
        equipment_class: 2,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2
      )

      invalid_inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "CLASS3",
        description: "Invalid Class Equipment",
        location: "Test Location",
        equipment_class: 3,  # Invalid class
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2
      )

      expect(valid_inspection1).to be_valid
      expect(valid_inspection2).to be_valid
      expect(invalid_inspection).not_to be_valid
      expect(invalid_inspection.errors[:equipment_class]).to include("is not included in the list")
    end

    # Test with boundary values for fuse_rating
    it "validates fuse_rating must be between 0 and 32" do
      valid_inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "FUSE32",
        description: "Max Fuse Equipment",
        location: "Test Location",
        equipment_class: 1,
        fuse_rating: 32,  # Maximum valid value
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2
      )

      invalid_inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "FUSE33",
        description: "Invalid Fuse Equipment",
        location: "Test Location",
        equipment_class: 1,
        fuse_rating: 33,  # Invalid value
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2
      )

      expect(valid_inspection).to be_valid
      expect(invalid_inspection).not_to be_valid
      expect(invalid_inspection.errors[:fuse_rating]).to include("must be less than or equal to 32")
    end

    # Test with precise floating point numbers
    it "handles precise decimal values for measurements" do
      inspection = Inspection.new(
        user: user,
        inspector: "Precision Tester",
        serial: "PREC123",
        description: "Precision Test Equipment",
        location: "Calibration Lab",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.001,       # Very low earth resistance
        insulation_mohms: 500,
        leakage: 0.0001,         # Very low leakage
        passed: true,
        comments: "Precision measurements test"
      )

      expect(inspection).to be_valid
      inspection.save!

      # Verify decimal precision was maintained
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.earth_ohms).to eq(0.001)
      expect(retrieved.leakage).to eq(0.0001)
    end

    # Test search functionality with special characters
    it "performs search with special characters" do
      # Create inspection with special characters in serial
      Inspection.create!(
        user: user,
        inspector: "Search Tester",
        serial: "SPEC!@#$%^&*()_+",
        description: "Special Characters Equipment",
        location: "Test Lab",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true
      )

      # Test searching for various patterns
      expect(Inspection.search("SPEC!@#").count).to eq(1)
      expect(Inspection.search("%^&*").count).to eq(1)
      expect(Inspection.search("()_+").count).to eq(1)
      expect(Inspection.search("NONEXISTENT").count).to eq(0)
    end

    # Test date validation and handling
    it "handles edge case dates" do
      # Far future dates
      future_inspection = Inspection.new(
        user: user,
        inspector: "Future Tester",
        serial: "FUTURE123",
        description: "Future Equipment",
        location: "Time Lab",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true,
        inspection_date: Date.today + 50.years,         # Far future inspection date
        reinspection_date: Date.today + 100.years       # Far future reinspection date
      )

      expect(future_inspection).to be_valid
      future_inspection.save!

      retrieved = Inspection.find(future_inspection.id)
      expect(retrieved.inspection_date).to eq(Date.today + 50.years)
      expect(retrieved.reinspection_date).to eq(Date.today + 100.years)
    end
  end

  describe "image attachment functionality" do
    it "can have an image attached" do
      inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "IMAGE001",
        description: "Test Equipment with Image",
        location: "Test Location",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true
      )

      # Create a test image
      file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg")
      inspection.image.attach(file)

      expect(inspection).to be_valid
      expect(inspection.image).to be_attached
    end

    it "validates file size" do
      inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "IMAGE002",
        description: "Test Equipment with Large Image",
        location: "Test Location",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true
      )

      # Mock a very large file
      allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(20.megabytes)
      file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg")
      inspection.image.attach(file)

      expect(inspection).not_to be_valid
      expect(inspection.errors[:image]).to include("cannot be larger than 10MB")
    end
  end

  describe "search functionality" do
    before do
      # Create test records for search
      Inspection.create!(
        user: user,
        inspector: "Search Tester 1",
        serial: "SEARCH001",
        description: "Search Test Equipment 1",
        location: "Search Lab",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true
      )

      Inspection.create!(
        user: user,
        inspector: "Search Tester 2",
        serial: "ANOTHER999",
        description: "Search Test Equipment 2",
        location: "Search Lab",
        equipment_class: 2,
        visual_pass: false,
        fuse_rating: 5,
        earth_ohms: 1.5,
        insulation_mohms: 100,
        leakage: 0.5,
        passed: false
      )
    end

    it "finds records by partial serial match" do
      expect(Inspection.search("SEARCH").count).to eq(1)
      expect(Inspection.search("ANOTHER").count).to eq(1)
      expect(Inspection.search("999").count).to eq(1)
      expect(Inspection.search("001").count).to eq(1)
    end

    it "returns empty collection when no match found" do
      expect(Inspection.search("NONEXISTENT").count).to eq(0)
    end

    it "is case-insensitive when searching" do
      expect(Inspection.search("search").count).to eq(1)
      expect(Inspection.search("another").count).to eq(1)

      # Create a record with lowercase serial
      Inspection.create!(
        user: user,
        inspector: "Case Tester",
        serial: "lowercase123",
        description: "Case Test Equipment",
        location: "Case Lab",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.2,
        passed: true
      )

      expect(Inspection.search("LOWERCASE").count).to eq(1)
      expect(Inspection.search("lowercase").count).to eq(1)
    end
  end
end
