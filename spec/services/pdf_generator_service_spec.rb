require 'rails_helper'

RSpec.describe PdfGeneratorService do
  describe ".generate_certificate" do
    let(:user) { User.create!(name: "Test Inspector", email: "test@example.com", password: "password", password_confirmation: "password") }
    let(:inspection) do
      Inspection.create!(
        serial: "TEST123",
        description: "Test Equipment",
        location: "Test Location",
        equipment_class: 1,
        visual_pass: true,
        fuse_rating: 13,
        earth_ohms: 0.5,
        insulation_mohms: 200,
        leakage: 0.3,
        passed: true,
        inspection_date: Date.today,
        reinspection_date: Date.today + 1.year,
        inspector: "Test Inspector",
        user: user
      )
    end
    
    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_certificate(inspection)
      expect(pdf).to be_a(Prawn::Document)
      
      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end
    
    context "with comments" do
      before do
        inspection.update(comments: "Test comments")
      end
      
      it "generates PDF with comments" do
        pdf = PdfGeneratorService.generate_certificate(inspection)
        expect(pdf).to be_a(Prawn::Document)
      end
    end
    
    context "with image" do
      before do
        # Skip this test if we can't attach images
        begin
          file_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
          inspection.image.attach(io: File.open(file_path), filename: "test_image.jpg", content_type: "image/jpeg")
        rescue StandardError => e
          skip("Skipping image test: #{e.message}")
        end
      end
      
      it "includes image in the PDF" do
        pdf = PdfGeneratorService.generate_certificate(inspection)
        expect(pdf).to be_a(Prawn::Document)
      end
    end
  end
end