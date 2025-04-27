class InspectionsController < ApplicationController
  before_action :require_login, except: [:new]

  def index
    @inspections = Inspection.all.order(created_at: :desc)
  end

  def show
    @inspection = Inspection.find(params[:id])
  end

  def new
    @inspection = Inspection.new
    @inspection.inspection_date = Date.today
    @inspection.reinspection_date = Date.today + 1.year
  end

  def create
    @inspection = Inspection.new(inspection_params)

    if @inspection.save
      flash[:success] = "Inspection record created successfully!"
      redirect_to @inspection
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @inspection = Inspection.find(params[:id])
  end

  def update
    @inspection = Inspection.find(params[:id])

    if @inspection.update(inspection_params)
      flash[:success] = "Inspection record updated successfully!"
      redirect_to @inspection
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inspection = Inspection.find(params[:id])
    @inspection.destroy

    flash[:success] = "Inspection record deleted successfully!"
    redirect_to inspections_path
  end

  def search
    @inspections = if params[:query].present?
      Inspection.search(params[:query])
    else
      Inspection.all
    end
  end

  def certificate
    require "prawn/table"

    @inspection = Inspection.find_by(id: params[:id])

    unless @inspection
      flash[:danger] = "Inspection record not found"
      redirect_to inspections_path and return
    end

    pdf_data = Prawn::Document.new do |pdf|
      # Register external fonts for proper UTF-8 support
      font_path = Rails.root.join("app", "assets", "fonts")
      pdf.font_families.update(
        "NotoSans" => {
          normal: "#{font_path}/NotoSans-Regular.ttf",
          bold: "#{font_path}/NotoSans-Bold.ttf",
          italic: "#{font_path}/NotoSans-Regular.ttf",
          bold_italic: "#{font_path}/NotoSans-Bold.ttf"
        },
        "NotoEmoji" => {
          normal: "#{font_path}/NotoEmoji-Regular.ttf"
        }
      )
      
      # Use our UTF-8 compatible font throughout the document
      pdf.font "NotoSans"
      
      pdf.text "PAT Inspection Certificate", size: 20, style: :bold, align: :center
      pdf.move_down 20

      # Header with border
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
        pdf.stroke_bounds
        pdf.move_down 15
        pdf.text "Serial Number: #{@inspection.serial}", align: :center, size: 14
        pdf.text (@inspection.passed ? "PASSED" : "FAILED").to_s, align: :center, size: 14, style: :bold, color: @inspection.passed ? "009900" : "CC0000"
      end

      pdf.move_down 20

      # Equipment details
      pdf.text "Equipment Details", size: 14, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      data = [
        ["Description", @inspection.description],
        ["Location", @inspection.location],
        ["Equipment Class", "Class #{@inspection.equipment_class} #{(@inspection.equipment_class == 1) ? "(Earthed)" : "(Double Insulated)"}"]
      ]

      pdf.table(data, width: pdf.bounds.width) do
        cells.borders = []
        cells.padding = [5, 10]
        columns(0).font_style = :bold
        columns(0).width = 150
        row(0..2).background_color = "EEEEEE"
        row(0..2).borders = [:bottom]
        row(0..2).border_color = "DDDDDD"
      end

      pdf.move_down 20

      # Test results
      pdf.text "Test Results", size: 14, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      results = [
        ["Inspection Date", @inspection.inspection_date&.strftime("%d/%m/%Y")],
        ["Re-inspection Due", @inspection.reinspection_date&.strftime("%d/%m/%Y")],
        ["Inspector", @inspection.inspector],
        ["Visual Inspection", @inspection.visual_pass ? "PASS" : "FAIL"],
        ["Fuse Rating", "#{@inspection.fuse_rating}A"],
        ["Earth Continuity", "#{@inspection.earth_ohms} Ohms"],
        ["Insulation Resistance", "#{@inspection.insulation_mohms} MOhms"],
        ["Leakage Current", "#{@inspection.leakage} mA"],
        ["Overall Result", @inspection.passed ? "PASS" : "FAIL"]
      ]

      passed = @inspection.passed

      pdf.table(results, width: pdf.bounds.width) do
        cells.borders = []
        cells.padding = [5, 10]
        columns(0).font_style = :bold
        columns(0).width = 150
        row(0..8).background_color = "EEEEEE"
        row(0..8).borders = [:bottom]
        row(0..8).border_color = "DDDDDD"
        row(8).background_color = passed ? "CCFFCC" : "FFCCCC" if row(8)
      end

      # Comments if any
      if @inspection.comments.present?
        pdf.move_down 20
        pdf.text "Comments", size: 14, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 10
        pdf.text @inspection.comments
      end

      # Footer
      pdf.move_down 30
      pdf.text "This certificate was generated on #{Time.now.strftime("%d/%m/%Y at %H:%M")}", size: 10, align: :center, style: :italic
      pdf.text "PAT Inspection Logger", size: 10, align: :center, style: :italic
    end

    send_data pdf_data.render,
      filename: "PAT_Certificate_#{@inspection.serial}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  private

  def inspection_params
    params.require(:inspection).permit(
      :inspection_date,
      :reinspection_date,
      :inspector,
      :serial,
      :description,
      :location,
      :equipment_class,
      :visual_pass,
      :fuse_rating,
      :earth_ohms,
      :insulation_mohms,
      :leakage,
      :passed,
      :comments
    )
  end
end
