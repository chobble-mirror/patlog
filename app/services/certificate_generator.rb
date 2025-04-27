require 'prawn'

class CertificateGenerator
  def initialize(inspection)
    @inspection = inspection
  end

  def generate
    pdf = Prawn::Document.new
    pdf.text "PAT Inspection Certificate", size: 20, style: :bold
    pdf.move_down 20

    # Inspection details
    pdf.text "Serial Number: \#{@inspection.serial}"
    pdf.text "Description: \#{@inspection.description}"
    pdf.text "Location: \#{@inspection.location}"
    pdf.text "Inspection Date: \#{@inspection.inspection_date.strftime('%d/%m/%Y')}"
    pdf.text "Re-inspection Date: \#{@inspection.reinspection_date.strftime('%d/%m/%Y')}"
    pdf.text "Inspector: \#{@inspection.inspector}"

    # Test results
    pdf.move_down 20
    pdf.text "Test Results", style: :bold
    pdf.text "Class: \#{@inspection.equipment_class}"
    pdf.text "Visual Inspection: \#{@inspection.visual_pass ? 'PASS' : 'FAIL'}"
    pdf.text "Fuse Rating: \#{@inspection.fuse_rating}A"
    pdf.text "Earth Continuity: \#{@inspection.earth_ohms} Ω"
    pdf.text "Insulation Resistance: \#{@inspection.insulation_mohms} MΩ"
    pdf.text "Leakage Current: \#{@inspection.leakage} mA"
    pdf.text "Overall Result: \#{@inspection.passed ? 'PASS' : 'FAIL'}", style: :bold

    # Comments
    if @inspection.comments.present?
      pdf.move_down 20
      pdf.text "Comments:", style: :bold
      pdf.text @inspection.comments
    end

    # Save to file - create directory if it doesn't exist
    dir_path = Rails.root.join('public', 'certificates')
    FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)

    filename = "PAT_Certificate_\#{@inspection.serial}_\#{Time.now.to_i}.pdf"
    pdf_path = dir_path.join(filename)
    pdf.render_file(pdf_path)

    # Return the path relative to public for easier linking
    "/certificates/\#{filename}"
  end
end
