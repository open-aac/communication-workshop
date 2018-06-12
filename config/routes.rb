require 'resque/server'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  ember_handler = 'render#default'
  root ember_handler

  protected_resque = Rack::Auth::Basic.new(Resque::Server.new) do |username, password|
    u = User.find_by_path(username)
    u && u.admin? && u.valid_password?(password)
  end
  mount protected_resque, :at => "/resque"

  get '/login' => ember_handler
  post '/token' => 'session#token'
  get '/terms' => 'render#terms'
  get '/privacy' => 'render#privacy'
  get '/register' => ember_handler
  get '/api/v1/token_check' => 'session#token_check'
  get '/auth/coughdrop/:id' => 'session#coughdrop_auth'
  get '/scratch/:page_id' => ember_handler
  get '/users/:user_name' => ember_handler
  get '/users/links/:user_id' => 'session#user_redirect'
  get '/words/:locale' => ember_handler
  get '/categories/:locale' => ember_handler
  get '/forgot_password' => ember_handler
  get '/users/:user_name/password_reset/:code' => ember_handler
  get '/books/launch' => 'render#book'
  get '/books' => ember_handler

  protected_resque = Rack::Auth::Basic.new(Resque::Server.new) do |username, password|
    u = User.find_by(:user_name => username)
    u && u.settings['admin'] && u.valid_password?(password)
  end
  mount protected_resque, :at => "/resque"

  scope '/words/:word/:locale' do
    get '/' => ember_handler
    get '/quizzes/:quiz_id' => ember_handler
    get '/stories/:story_id' => ember_handler
    get '/lessons/:lesson_id' => ember_handler
    get '/practice' => ember_handler
    get '/projects/:project_id' => ember_handler
    get '/pictures/:picture_id' => ember_handler
    get '/role_plays/:play_id' => ember_handler
    get '/stats' => ember_handler
  end
  scope '/categories/:category/:locale' do
    get '/' => ember_handler
  end
  scope '/books/:id' do
    get '/' => ember_handler
  end
  
  book_id_regex = /\d+-[\w-]+/

  scope 'api/v1', module: 'api' do
    post '/external' => 'users#external_activities'
    get '/images/pixabay/:id' => 'search#pixabay_redirect'
    get '/words/suggestions' => 'words#suggestions'
    get '/words/:id/defaults' => 'words#defaults'
    resources :words
    resources :images
    post '/words/:id/add' => 'words#add'
    post '/words/:id/remove' => 'words#remove'
    post '/words/:id/star/:activity_id' => 'words#star_activity'
    post '/words/:id/unstar/:activity_id' => 'words#unstar_activity'
    post '/words/packet' => 'words#generate_packet'
    post '/activities/:id/perform' => 'words#perform_activity'
    resources :categories
    get '/books/json' => 'books#book_json'
    resources :books, {constraints: {id: book_id_regex}} do
      post '/print' => 'books#print'
    end
    resources :lessons
    get '/events' => 'users#events'
    resources :users do
      get '/word_map' => 'users#full_map'
      get '/words' => 'users#words'
      post '/update_word_map' => 'users#update_word_map'
      post '/password_reset' => 'users#forgot_password', on: :collection
      post '/password_reset' => 'users#reset_password'
    end
    get '/search/books' => 'search#books'
    post '/search/tallies' => 'search#tallies'
    get '/search/tallies' => 'search#tallies'
    get "progress/:id" => "progress#progress"
  end
end
