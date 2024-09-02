100.times do |i|
  post = Post.create!(title: "Post #{i + 1}", content: "This is the content of post #{i + 1}")
  5.times do |j|
    Comment.create!(post: post, content: "This is comment #{j + 1} for post #{i + 1}")
  end
end
