Rails.application.routes.draw do
  # ルートにPostsのindexアクションを設定します
  root 'posts#index'

  resources :posts, only: [:index]
end
