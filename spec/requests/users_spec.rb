require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "returns http success" do
      get "/signup"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /signup" do
    it "creates a user and redirects" do
      post "/signup", params: {
        user: {
          email: "newuser@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }

      expect(response).to have_http_status(:redirect)
    end
  end
end
