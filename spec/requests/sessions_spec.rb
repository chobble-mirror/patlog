require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "returns http success" do
      get "/login"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login" do
    it "authenticates a user and redirects" do
      # Create a test user
      User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )

      # Log in with credentials
      post "/login", params: {session: {email: "test@example.com", password: "password"}}

      # Should redirect to inspections path after login
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /logout" do
    it "logs out a user and redirects" do
      # Create a session
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(double("User"))

      # Log out
      delete "/logout"

      expect(response).to have_http_status(:redirect)
    end
  end
end
