class ApplicationController < ActionController::Base
  include Authentication
  before_action :require_login

  helper_method :current_user, :user_signed_in?

  private

  def require_login
    unless logged_in?
      flash[:error] = "ログインが必要です"
      redirect_to login_path
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end
end
