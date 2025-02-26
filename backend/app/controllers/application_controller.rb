class ApplicationController < ActionController::Base
  include Authentication
  before_action :require_login

  private

  def require_login
    unless logged_in?
      flash[:error] = "ログインが必要です"
      redirect_to login_path
    end
  end
end
