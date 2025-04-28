class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_admin, only: [:index, :edit, :update, :destroy]
  before_action :set_user, only: [:edit, :update, :destroy]
  
  def index
    @users = User.all
  end
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Account created successfully!"
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @user.update(user_params)
      flash[:success] = "User updated successfully!"
      redirect_to users_path
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.destroy
    flash[:success] = "User deleted successfully!"
    redirect_to users_path
  end

  private
  
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    if current_user&.admin?
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :inspection_limit)
    else
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
  end
  
  def require_admin
    unless current_user&.admin?
      flash[:danger] = "You are not authorized to access this page"
      redirect_to root_path
    end
  end
end
