Spree::Core::Engine.add_routes do
  devise_for :spree_user,
             :class_name => 'Spree::User',
             :skip => [:registrations, :unlocks, :omniauth_callbacks],
             :controllers => { :sessions => 'spree/user_sessions',
                               :passwords => 'spree/user_passwords',
                               :confirmations => 'spree/user_confirmations' },
             :path_names => { :sign_out => 'logout' },
             :path_prefix => :user

  resources :users, :only => [:edit, :update]

  devise_scope :spree_user do
    get '/login' => 'user_sessions#new', :as => :login
    post '/login' => 'user_sessions#create', :as => :create_new_session
    get '/logout' => 'user_sessions#destroy', :as => :logout
    get '/password/recover' => 'user_passwords#new', :as => :recover_password
    post '/password/recover' => 'user_passwords#create', :as => :reset_password
    get '/password/change' => 'user_passwords#edit', :as => :edit_password
    put '/password/change' => 'user_passwords#update', :as => :update_password
    get '/confirm' => 'user_confirmations#show', :as => :confirmation if Spree::Auth::Config[:confirmable]
    post '/user/oauth/facebook/callback' => 'user_sessions#facebook'
  end

  get '/checkout/registration' => 'checkout#registration', :as => :checkout_registration
  get '/checkout/guest' => 'checkout#guest', :as => :checkout_guest
  put '/checkout/registration' => 'checkout#update_registration', :as => :update_checkout_registration



  resource :account, :controller => 'users', except: [:show]

  namespace :admin do
    devise_for :spree_user,
               :class_name => 'Spree::User',
               :controllers => { :sessions => 'spree/admin/user_sessions',
                                 :passwords => 'spree/admin/user_passwords' },
               :skip => [:unlocks, :omniauth_callbacks, :registrations],
               :path_names => { :sign_out => 'logout' },
               :path_prefix => :user
    devise_scope :spree_user do
      get '/authorization_failure', :to => 'user_sessions#authorization_failure', :as => :unauthorized
      get '/login' => 'user_sessions#new', :as => :login
      post '/login' => 'user_sessions#create', :as => :create_new_session
      get '/logout' => 'user_sessions#destroy', :as => :logout
    end

  end
end
