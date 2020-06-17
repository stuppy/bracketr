Rails.application.routes.draw do
  root 'homepage#index'
  # Map everythign else to the homepage EXCEPT anything in /api/
  get '/*path' => 'homepage#index', constraints: -> (req) { !(req.fullpath =~ /^\/api\/.*/) }
end
