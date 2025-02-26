module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in? if respond_to?(:helper_method)
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      flash[:error] = "ログインが必要です"
      redirect_to login_path
    end
  end
end