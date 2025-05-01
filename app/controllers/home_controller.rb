class HomeController < ApplicationController
  skip_before_action :require_login, only: [:index, :about]

  def index
  end

  def about
  end
end
