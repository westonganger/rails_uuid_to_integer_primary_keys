class Post < ApplicationRecord

  belongs_to :author
  belongs_to :owner, polymorphic: true
  has_many :comments

  has_and_belongs_to_many :posts, foreign_key: :post_1_id, association_foreign_key: :post_2_id
  has_many :post_posts
  has_many :posts, through: :post_posts

end
