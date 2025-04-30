class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_admin, only: [:index, :edit, :update, :destroy]
  before_action :set_user, only: [:edit, :update, :destroy, :change_password, :update_password]
  before_action :require_correct_user, only: [:change_password, :update_password]

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
      flash[:success] = "Account created"
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = "User updated"
      redirect_to users_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "User deleted"
    redirect_to users_path
  end

  def change_password
  end

  def update_password
    if @user.authenticate(params[:user][:current_password])
      if @user.update(password_params)
        flash[:success] = "Password updated"
        redirect_to root_path
      else
        render :change_password, status: :unprocessable_entity
      end
    else
      @user.errors.add(:current_password, "is incorrect")
      render :change_password, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    if current_user&.admin?
      params.require(:user).permit(:email, :password, :password_confirmation, :inspection_limit)
    else
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end

  def require_admin
    unless current_user&.admin?
      flash[:danger] = "You are not authorized to access this page"
      redirect_to root_path
    end
  end

  def require_correct_user
    unless current_user == @user
      flash[:danger] = "You can only change your own password"
      redirect_to root_path
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
