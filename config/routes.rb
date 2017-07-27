require 'resque/server'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  ember_handler = 'render#default'
  root ember_handler

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
  
  scope 'api/v1', module: 'api' do
    resources :words
    get '/search/books' => 'search#books'
  end
end
