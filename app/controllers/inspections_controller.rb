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
