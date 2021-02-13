class SetUpTestTables < ActiveRecord::Migration::Current

  def change
    create_table :posts, id: :uuid do |t|
      t.string :name, :content
      t.references :author
      t.timestamps
    end

    create_table :post_posts, id: :uuid do |t|
      t.references :post_1
      t.references :post_2
      t.timestamps
    end

    create_table :comments, id: :uuid do |t|
      t.string :content
      t.references :post
      t.timestamps
    end

    create_table :authors, id: :uuid do |t|
      t.string :name
      t.timestamps
    end
  end

end
