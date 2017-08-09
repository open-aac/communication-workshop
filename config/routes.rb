require 'resque/server'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  ember_handler = 'render#default'
  root ember_handler
  get '/login' => ember_handler
  post '/token' => 'session#token'
  get '/api/v1/token_check' => 'session#token_check'

  protected_resque = Rack::Auth::Basic.new(Resque::Server.new) do |username, password|
    u = User.find_by(:user_name => username)
    u && u.settings['admin'] && u.valid_password?(password)
  end
  mount protected_resque, :at => "/resque"

  scope '/words/:word/:locale' do
    get '/' => ember_handler
    get '/quizzes/:quiz_id' => ember_handler
    get '/stories/:story_id' => ember_handler
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
    resources :words
    resources :categories
    resources :books, {constraints: {id: book_id_regex}}
    get '/books/:id/json' => 'books#book_json', constraints: {id: book_id_regex}
    get '/search/books' => 'search#books'
  end
end
