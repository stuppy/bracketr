Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'brackets', to: 'brackets#index', as: "brackets_index"
      get 'brackets/:id', to: 'brackets#show', as: "brackets_show"
    end
  end
  root 'homepage#index'
  # Map everythign else to the homepage EXCEPT anything in /api/
  get '/*path' => 'homepage#index', constraints: -> (req) { !(req.fullpath =~ /^\/api\/.*/) }
end
