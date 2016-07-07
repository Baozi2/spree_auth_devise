class Spree::UserSessionsController < Devise::SessionsController
  helper 'spree/base'

  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Store

  skip_before_action :verify_authenticity_token, only: [:facebook]
  def create
    authenticate_spree_user!

    if spree_user_signed_in?
      respond_to do |format|
        format.html {
          flash[:success] = Spree.t(:logged_in_succesfully)
          redirect_back_or_default(after_sign_in_path_for(spree_current_user))
        }
        format.js {
          render :json => {:user => spree_current_user,
                           :ship_address => spree_current_user.ship_address,
                           :bill_address => spree_current_user.bill_address}.to_json
        }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:error] = t('devise.failure.invalid')
          render :new
        }
        format.js {
          render :json => { error: t('devise.failure.invalid') }, status: :unprocessable_entity
        }
      end
    end
  end


  def facebook

    if params[:facebook_access_token]
      begin
        facebook_access_token = params[:facebook_access_token]
        graph = Koala::Facebook::API.new(facebook_access_token)
        profile = graph.get_object("me")
        facebook_uid = profile["id"]
        existing_user = Spree.user_class.where(facebook_uid: facebook_uid).first
        if existing_user
          if existing_user.facebook_access_token != facebook_access_token
            existing_user.facebook_access_token = facebook_access_token
            existing_user.save!
          end
          sign_in(existing_user)
          render json: { status: 1 }
        else
          email = profile["email"]
          name = profile["name"]
          if not email.blank? and Spree.user_class.where(email: email).exists?
            #raise_doorkeeper_typed_error(:user_exists)
            Rails.logger.error('facebook  login   email had')
            ExceptionLogger.log_error("facebook  login   email had  ")
            render json: { status: 0 }
          else
            if email.blank? then
              # temp hack
              email = "#{profile['id']}@nonexistentfbuseremail.com"
            end
            @user = Spree.user_class.create!(
                email: email,
                name: name,
                facebook_uid: facebook_uid,
                facebook_access_token: facebook_access_token,
                password: Devise.friendly_token.first(8)
            )
            sign_in(@user)
            render json: { status: 1 }
          end
        end
      rescue Koala::Facebook::AuthenticationError => e
        Rails.logger.error(e)
        ExceptionLogger.log_error(e)
        #raise_doorkeeper_typed_error(:invalid_facebook_access_token)
        render json: { status: 0 }
      rescue => e
        Rails.logger.error(e)
        render json: { status: 0 }
      end
    end
  end

  private
    def accurate_title
      Spree.t(:login)
    end

    def redirect_back_or_default(default)
      redirect_to(session["spree_user_return_to"] || default)
      session["spree_user_return_to"] = nil
    end
end
