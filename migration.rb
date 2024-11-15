class ChangeUuidToIntegerPrimaryKeys < ActiveRecord::Migration::Current
  BACKUP_COL_PREFIX = "tmp_old_uuid_".freeze

  ### Warning: Only set to `true` if you know what your doing and have a backup ready and working
  ### Strongly recommended to remove backup columns in a seperate migration, so that you are able to tie up any missed references, etc.
  REMOVE_BACKUP_ID_COLUMNS_WITH_INITIAL_MIGRATION = false

  def change
    ### LOAD ALL MODELS for `.subclasses` method
    Dir.glob(Rails.root.join("app/models/*.rb")).each{|f| require(f) }   
 
    ### PERFORM CONVERSION FOR ALL CLASSES, KEEPS OLD ID BACKUP COLUMNS
    ApplicationRecord.subclasses.each do |klass|
      self.klass_convert_uuid_primary_key_to_integer(klass)
    end

    ### REMOVE OLD ID BACKUP COLUMNS
    if REMOVE_BACKUP_ID_COLUMNS_WITH_INITIAL_MIGRATION 
       ApplicationRecord.subclasses.each do |klass|
        klass.column_names.each do |col_name|
          if col_name.start_with?(BACKUP_COL_PREFIX)
            remove_column klass.table_name, col_name
          end
        end
      end
    end
  end

  private

  def klass_convert_uuid_primary_key_to_integer(primary_klass)   
    primary_klass.reset_column_information
    
    return if !primary_klass.table_exists?

    if primary_klass.column_for_attribute(primary_klass.primary_key).type == :uuid
      self.add_new_primary_key_and_keep_old_pkey(primary_klass)
  
      ### CREATE ID MAP
      klass_id_map = {}
  
      records = primary_klass.all
  
      if primary_klass.column_names.include?("created_at")
        records = records.reorder(created_at: :asc)
      end
  
      records.each_with_index do |record, i|
        old_id = record.send("#{BACKUP_COL_PREFIX}#{primary_klass.primary_key}")
  
        if record.send(primary_klass.primary_key).nil?
          new_id = i+1
          record.update_columns(primary_klass.primary_key => new_id)
        else
          new_id = record.send(primary_klass.primary_key)
        end
  
        klass_id_map[old_id] = new_id
      end

      ### HANDLE REFERENCES TO KLASS WITHIN OTHER TABLES
      ApplicationRecord.subclasses.each do |reference_klass|
        reference_klass.reset_column_information
        
        next if !reference_klass.table_exists?

        reflections = reference_klass.reflect_on_all_associations(:belongs_to).select{|x| x.polymorphic? || x.klass == primary_klass }
          
        reflections.each do |reflection|
          if reference_klass.column_for_attribute(reflection.foreign_key).type == :uuid
            if reflection.polymorphic?
              self.handle_polymorphic_belongs_to(primary_klass, reference_klass, reflection) 
            else
              self.handle_normal_belongs_to(primary_klass, reference_klass, reflection, klass_id_map)
            end
          end
        end

        habtm_reflections = reference_klass.reflect_on_all_associations(:has_and_belongs_to_many).select{|x| x.klass == primary_klass }
    
        habtm_reflections.each do |reflection|
          if reference_klass.column_for_attribute(reflection.association_foreign_key).type == :uuid
            self.handle_has_and_belongs_to_many(primary_klass, reflection, id_map)
          end
        end
      end
    end
  end

  def add_new_primary_key_and_keep_old_pkey(klass)
    case klass.connection.adapter_name
    when "Mysql2"
      execute "ALTER TABLE #{klass.table_name} DROP PRIMARY KEY;"
    else
      result = klass.connection.execute("
        SELECT ('ALTER TABLE ' || table_schema || '.' || table_name || ' DROP CONSTRAINT ' || constraint_name) as my_query
        FROM information_schema.table_constraints
        WHERE table_name = '#{klass.table_name}' AND constraint_type = 'PRIMARY KEY';")
          
      sql_drop_constraint_command = result.values[0].first

      execute(sql_drop_constraint_command)
    end

    rename_column klass.table_name, klass.primary_key, "#{BACKUP_COL_PREFIX}#{klass.primary_key}"

    add_column klass.table_name, klass.primary_key, klass.connection.native_database_types[:primary_key]

    klass.reset_column_information
  end

  def change_reference_column_type(reference_table_name, foreign_key, reference_klass: nil, connection: nil)
    #null_constraint = reference_klass.columns.find{|x| x.name == foreign_key }.null
    if (connection || reference_klass.connection).index_exists?(reference_table_name, foreign_key)
      remove_index reference_table_name, foreign_key
    end
    rename_column reference_table_name, foreign_key, "#{BACKUP_COL_PREFIX}#{foreign_key}"
    add_column reference_table_name, foreign_key, :bigint#, null: null_constraint
    add_index reference_table_name, foreign_key
  end

  def handle_normal_belongs_to(reference_klass, reflection, klass_id_map)
    self.change_reference_column_type(reference_klass.table_name, reflection.foreign_key, reference_klass: reference_klass)

    reference_klass.reset_column_information

    records = reference_klass.where("#{reference_klass.table_name}.#{BACKUP_COL_PREFIX}#{reflection.foreign_key} IS NOT NULL")

    records.each do |record|
      old_id = record.send("#{BACKUP_COL_PREFIX}#{reflection.foreign_key}")

      if old_id
        new_id = klass_id_map[old_id]

        if new_id
          ### First Update Column ID Value
          record.update_columns(reflection.foreign_key => new_id)
        else
          # Orphan record, set reference ID as nil
          record.update_columns(reflection.foreign_key => nil)
        end
      end
    end
  end

  def handle_polymorphic_belongs_to(primary_klass, reference_klass, reflection, klass_id_map)
    self.change_reference_column_type(reference_klass.table_name, reflection.foreign_key, reference_klass: reference_klass)

    reference_klass.reset_column_information
    
    records = reference_klass
      .where("#{reference_klass.table_name}.#{BACKUP_COL_PREFIX}#{reflection.foreign_key} IS NOT NULL")
      .where("#{reflection.foreign_type}" => primary_klass.name)

    records.each do |record|
      old_id = record.send("#{BACKUP_COL_PREFIX}#{reflection.foreign_key}")

      if old_id
        new_id = klass_id_map[old_id]

        if new_id
          ### First Update Column ID Value
          record.update_columns(reflection.foreign_key => new_id)
        else
          # Orphan record, set reference ID as nil
          record.update_columns(reflection.foreign_key => nil)
        end
      end
    end
  end

  def handle_has_and_belongs_to_many(reflection, klass_id_map, primary_klass)
    self.change_reference_column_type(reference_klass.table_name, reflection.foreign_key, connection: reflection.klass.connection)

    klass_id_map.each do |old_id, new_id|
      if new_id
        ### First Update Column ID Value
        execute "UPDATE #{reflection.join_table} SET #{reflection.association_foreign_key} = '#{new_id}' WHERE #{BACKUP_COL_PREFIX}#{reflection.association_foreign_key} = '#{old_id}'"
      else
        # Orphan record, leave value empty
      end
    end

    remove_column reflection.join_table, "#{BACKUP_COL_PREFIX}#{reflection.association_foreign_key}"
  end

end
