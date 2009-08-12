class TokensController < ApplicationController

  def show
    @token = Token::Base.find_by_code(params[:code])

    if @token.valid_token?

      redirect_target = @token.handle_redirect
      if redirect_target.nil?
        flash[:error] = "Sorry, we couldn't handle the token #{params[:code]}."
      else
        session[:token_code] = @token.code if @token.store_in_session?
        return redirect_to(redirect_target) # success
      end

    elsif @token.exists?
      flash[:error] = "Token " + @token.errors[:base]
    else
      raise ActiveRecord::RecordNotFound 
    end

    redirect_to '/' # error (message in flash)
  end
end
