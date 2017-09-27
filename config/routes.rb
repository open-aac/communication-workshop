require 'resque/server'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  ember_handler = 'render#default'
  root ember_handler
  get '/login' => ember_handler
  post '/token' => 'session#token'
  get '/api/v1/token_check' => 'session#token_check'
  get '/auth/coughdrop/:id' => 'session#coughdrop_auth'
  get '/scratch/:page_id' => ember_handler
  get '/users/:user_name' => ember_handler

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
    get '/words/suggestions' => 'words#suggestions'
    get '/words/:id/defaults' => 'words#defaults'
    resources :words
    post '/words/:id/add' => 'words#add'
    post '/words/:id/remove' => 'words#remove'
    post '/words/:id/star/:activity_id' => 'words#star_activity'
    post '/words/:id/unstar/:activity_id' => 'words#unstar_activity'
    post '/activities/:id/perform' => 'words#perform_activity'
    resources :categories
    resources :books, {constraints: {id: book_id_regex}}
    resources :lessons
    get '/events' => 'users#events'
    resources :users do
      get '/word_map' => 'users#full_map'
      get '/words' => 'users#words'
    end
    get '/books/:id/json' => 'books#book_json', constraints: {id: book_id_regex}
    get '/search/books' => 'search#books'
    post '/search/tallies' => 'search#tallies'
    get '/search/tallies' => 'search#tallies'
  end
end
