class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include SessionsHelper
  
  before_action :require_login

  private

  def require_login
    unless logged_in?
      flash[:danger] = "Please log in to access this page"
      redirect_to login_path
    end
  end
end
