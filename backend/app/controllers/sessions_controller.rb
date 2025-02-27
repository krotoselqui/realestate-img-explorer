class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    flash.clear
  end

  def create
    user = User.authenticate_by_email_or_username(params[:login], params[:password])
    if user
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "ログインしました"
    else
      flash.now.alert = "ログインIDまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "ログアウトしました", status: :see_other
  end
end