require "rails_helper"

RSpec.describe ImageProcessorService, type: :service do
  describe "#process" do
    it "returns nil if no image is attached" do
      inspection = Inspection.new
      expect(ImageProcessorService.process(inspection.image)).to be_nil
    end
    
    it "processes an attached image" do
      inspection = Inspection.new(
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
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      inspection.image.attach(file)
      
      # Skip the actual image processing in tests
      allow(inspection.image).to receive(:content_type).and_return("image/jpeg")
      allow(inspection.image).to receive(:variant).and_return(double("Variant"))
      
      result = ImageProcessorService.process(inspection.image)
      expect(result).not_to be_nil
    end
  end
  
  describe "#thumbnail" do
    it "returns nil if no image is attached" do
      inspection = Inspection.new
      expect(ImageProcessorService.thumbnail(inspection.image)).to be_nil
    end
    
    it "generates a thumbnail for an attached image" do
      inspection = Inspection.new(
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
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      inspection.image.attach(file)
      
      # Skip the actual image processing in tests
      allow(inspection.image).to receive(:variant).and_return(double("Variant"))
      
      result = ImageProcessorService.thumbnail(inspection.image)
      expect(result).not_to be_nil
    end
  end
end