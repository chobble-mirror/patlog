require "rails_helper"

RSpec.describe "Inspections", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password", password_confirmation: "password") }

  let(:valid_inspection_attributes) do
    {
      inspection_date: Date.today,
      reinspection_date: Date.today + 1.year,
      inspector: "Test Inspector",
      serial: "TEST123",
      description: "Test Equipment",
      location: "Test Location",
      equipment_class: 1,
      visual_pass: true,
      fuse_rating: 13,
      earth_ohms: 0.5,
      insulation_mohms: 200,
      leakage: 0.2,
      passed: true,
      comments: "Test comments"
    }
  end

  describe "authentication requirements" do
    it "redirects to login page when not logged in for index" do
      get "/inspections"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for show" do
      # Create a test inspection with user association
      inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

      get "/inspections/#{inspection.id}"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for new inspection" do
      get "/inspections/new"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for create" do
      post "/inspections", params: {inspection: valid_inspection_attributes}
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for edit" do
      # Create a test inspection with user association
      inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

      get "/inspections/#{inspection.id}/edit"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for update" do
      # Create a test inspection with user association
      inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

      patch "/inspections/#{inspection.id}", params: {inspection: {description: "Updated Equipment"}}
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for destroy" do
      # Create a test inspection with user association
      inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

      delete "/inspections/#{inspection.id}"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end
  end

  describe "user_id association" do
    before do
      post "/login", params: {session: {email: user.email, password: "password"}}
    end

    it "assigns the current user's ID when creating a new inspection" do
      post "/inspections", params: {inspection: valid_inspection_attributes}

      # Verify a new inspection was created
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response).to have_http_status(:success)

      # Verify it was associated with the current user
      inspection = Inspection.last
      expect(inspection.user_id).to eq(user.id)
    end

    it "cannot override the user_id when creating a new inspection" do
      # Try to set user_id to another user
      post "/inspections", params: {
        inspection: valid_inspection_attributes.merge(user_id: other_user.id)
      }

      # Verify it still used the current user's ID
      inspection = Inspection.last
      expect(inspection.user_id).to eq(user.id)
      expect(inspection.user_id).not_to eq(other_user.id)
    end

    it "cannot override the user_id when updating an inspection" do
      # Create a test inspection with current user
      inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

      # Try to change the user_id during update
      patch "/inspections/#{inspection.id}", params: {
        inspection: {description: "Updated Description", user_id: other_user.id}
      }

      # Verify the description updated but not the user_id
      inspection.reload
      expect(inspection.description).to eq("Updated Description")
      expect(inspection.user_id).to eq(user.id)
      expect(inspection.user_id).not_to eq(other_user.id)
    end
  end

  describe "authorization requirements" do
    before do
      # Create two inspections, one for each user
      @user_inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))
      @other_inspection = Inspection.create!(valid_inspection_attributes.merge(
        user: other_user,
        serial: "OTHER123"
      ))
    end

    it "only shows the current user's inspections in the index" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password"}}

      get "/inspections"
      expect(response).to have_http_status(:success)

      # Verify only the current user's inspections are displayed
      expect(response.body).to include(@user_inspection.serial)
      expect(response.body).not_to include(@other_inspection.serial)
    end

    it "prevents viewing another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password"}}

      # Try to view another user's inspection
      get "/inspections/#{@other_inspection.id}"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")
    end

    it "prevents editing another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password"}}

      # Try to edit another user's inspection
      get "/inspections/#{@other_inspection.id}/edit"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")
    end

    it "prevents updating another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password"}}

      # Try to update another user's inspection
      patch "/inspections/#{@other_inspection.id}", params: {
        inspection: {description: "Should Not Update"}
      }

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")

      # Verify the description did not change
      @other_inspection.reload
      expect(@other_inspection.description).to eq("Test Equipment")
    end

    it "prevents deleting another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password"}}

      # Try to delete another user's inspection
      delete "/inspections/#{@other_inspection.id}"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")

      # Verify the inspection still exists
      expect(Inspection.exists?(@other_inspection.id)).to be true
    end
  end

  describe "when logged in" do
    before do
      post "/login", params: {session: {email: user.email, password: "password"}}
    end

    describe "GET /index" do
      it "returns http success" do
        get "/inspections"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /show" do
      it "returns http success for own inspection" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

        get "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /edit" do
      it "returns http success for own inspection" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(user: user))

        get "/inspections/#{inspection.id}/edit"
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /create" do
      it "creates a new inspection and redirects" do
        post "/inspections", params: {inspection: valid_inspection_attributes}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was created with correct attributes
        inspection = Inspection.last
        expect(inspection.serial).to eq("TEST123")
        expect(inspection.user_id).to eq(user.id)
      end

      it "creates a new inspection with image and redirects" do
        file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg")

        post "/inspections", params: {
          inspection: valid_inspection_attributes.merge(
            serial: "TEST999",
            description: "Test Equipment with Image",
            image: file
          )
        }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Check that the image was attached and user_id was set
        inspection = Inspection.find_by(serial: "TEST999")
        expect(inspection.image).to be_attached
        expect(inspection.user_id).to eq(user.id)
      end

      it "rejects non-image file uploads and shows validation error" do
        # Use a fixture for a text file (create one if it doesn't exist)
        file_path = Rails.root.join("spec", "fixtures", "files", "test.txt")

        # Upload the text file with text/plain content type
        text_file = fixture_file_upload(file_path, "text/plain")

        post "/inspections", params: {
          inspection: valid_inspection_attributes.merge(
            serial: "TEST1000",
            description: "Test Equipment with Non-Image File",
            image: text_file
          )
        }

        # Should not redirect because validation failed
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be an image file")

        # Inspection should not exist
        expect(Inspection.find_by(serial: "TEST1000")).to be_nil
      end

      it "doesn't create any ActiveStorage attachment when non-image file is uploaded" do
        original_attachment_count = ActiveStorage::Attachment.count

        # Use a fixture for a text file
        file_path = Rails.root.join("spec", "fixtures", "files", "test.txt")

        # Upload the text file with text/plain content type
        text_file = fixture_file_upload(file_path, "text/plain")

        post "/inspections", params: {
          inspection: valid_inspection_attributes.merge(
            serial: "TEST1001",
            description: "Test Equipment with Non-Image File",
            image: text_file
          )
        }

        # Verify no new attachment was created
        expect(ActiveStorage::Attachment.count).to eq(original_attachment_count)
      end
    end

    describe "PATCH /update" do
      it "updates own inspection and redirects" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(
          serial: "TEST456",
          user: user
        ))

        patch "/inspections/#{inspection.id}", params: {
          inspection: {description: "Updated Equipment"}
        }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was updated
        inspection.reload
        expect(inspection.description).to eq("Updated Equipment")
        expect(inspection.user_id).to eq(user.id)
      end

      it "rejects update with non-image file and shows validation error" do
        # Create initial inspection
        inspection = Inspection.create!(valid_inspection_attributes.merge(
          serial: "TEST789",
          user: user
        ))

        # Use a fixture for a text file
        file_path = Rails.root.join("spec", "fixtures", "files", "test.txt")

        # Upload the text file with text/plain content type
        text_file = fixture_file_upload(file_path, "text/plain")

        patch "/inspections/#{inspection.id}", params: {
          inspection: {
            description: "Updated with invalid file",
            image: text_file
          }
        }

        # Should not redirect because validation failed
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be an image file")

        # Inspection should not be updated
        inspection.reload
        expect(inspection.description).not_to eq("Updated with invalid file")
      end

      it "doesn't attach non-image file during update" do
        # Create initial inspection
        inspection = Inspection.create!(valid_inspection_attributes.merge(
          serial: "TEST790",
          user: user
        ))

        # Remember initial state
        original_attachment_count = ActiveStorage::Attachment.count

        # Use a fixture for a text file
        file_path = Rails.root.join("spec", "fixtures", "files", "test.txt")

        # Upload the text file with text/plain content type
        text_file = fixture_file_upload(file_path, "text/plain")

        patch "/inspections/#{inspection.id}", params: {
          inspection: {
            description: "Updated with invalid file",
            image: text_file
          }
        }

        # No new attachment should be created
        expect(ActiveStorage::Attachment.count).to eq(original_attachment_count)

        # Confirm that no image is attached to the inspection
        inspection.reload
        expect(inspection.image).not_to be_attached
      end
    end

    describe "DELETE /destroy" do
      it "deletes own inspection and redirects" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(
          serial: "TEST789",
          user: user
        ))

        delete "/inspections/#{inspection.id}"

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was deleted
        expect(Inspection.exists?(inspection.id)).to be false
      end
    end
  end
end
