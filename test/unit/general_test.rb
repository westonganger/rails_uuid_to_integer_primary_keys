require "test_helper"

require_relative "../../migration.rb"

class GeneralTest < ActiveSupport::TestCase

  setup do
    @klass = ChangeUuidToIntegerPrimaryKeys
  end

  teardown do
  end

  def test_change
    @klass.new.change
  end

  #### BELOW TESTS NOT REQUIRED

  # def test_klass_convert_uuid_primary_key_to_integer
  #   @klass.send(:klass_convert_uuid_primary_key_to_integer, Post)
  # end

  # def test_add_new_primary_key_and_keep_old_pkey(klass)
  #   @klass.send(:add_new_primary_key_and_keep_old_pkey, Post)
  # end

  # def test_change_reference_column_type
  #   @klass.send(:change_reference_column_type, Post.table_name, "post_id", reference_klass: Post, connection: nil)
  # end

  # def test_handle_normal_belongs_to
  #   @klass.send(:handle_normal_belongs_to, Post, reflection, id_map)
  # end

  # def test_handle_polymorphic_belongs_to(primary_klass, reference_klass, reflection, klass_id_map)
  #   @klass.send(:handle_polymorphic_belongs_to, Post, Post, reflection, klass_id_map)
  # end

  # def test_handle_has_and_belongs_to_many(reflection, klass_id_map, primary_klass)
  #   @klass.send(:handle_has_and_belongs_to_many, reflection, klass_id_map, Post)
  # end

end
