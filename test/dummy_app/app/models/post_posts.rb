class PostPosts < ActiveRecord::Base
  ### FOR HABTM TEST INTROSPECTION ONLY, DO NOT INHERIT FROM APPLICATION RECORD
  belongs_to :post_1, class_name: 'Post'
  belongs_to :post_2, class_name: 'Post'
end
