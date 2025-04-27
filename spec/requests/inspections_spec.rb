require 'rails_helper'

RSpec.describe "Inspections", type: :request do
  describe "GET /" do
    it "returns http success and renders new inspection form" do
      get "/"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
      expect(response.body).to include("PAT Inspection Logger")
      
      # Verify this is actually routing to inspections#new per our routes
      expect(controller.controller_name).to eq("inspections")
      expect(controller.action_name).to eq("new")
    end
  end

  describe "GET /index" do
    it "returns http success" do
      get "/inspections/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/inspections/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/inspections/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/inspections/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/inspections/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/inspections/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/inspections/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /search" do
    it "returns http success" do
      get "/inspections/search"
      expect(response).to have_http_status(:success)
    end
  end

end
