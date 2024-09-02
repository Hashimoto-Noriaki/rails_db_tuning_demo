class PostsController < ApplicationController
  def index
    @posts = Post.includes(:comments).all #Eager Loadを使用
    #@posts = Post.preload(:comments).all Preloadを使用可
  end
end
