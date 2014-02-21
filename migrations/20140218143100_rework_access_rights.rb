Sequel.migration do

  up do
  	alter_table(:access_rights) do
  		add_foreign_key :camera_id, :cameras
      add_foreign_key :grantor_id, :users
      add_column :status, Integer, null: false, default: 1
      drop_index [:token_id, :group, :right, :scope]
  	end

    self[:access_rights].where(group: 'camera').each do |record|
      camera = self[:cameras].where(exid: record[:scope]).first
      if !camera.nil?
        self[:access_rights].where(id: record[:id]).update(camera_id: camera[:id])
      else
        STDERR.puts "Unable to find a camera with an exid of '#{record[:scope]}', deleting record."
        self[:access_rights].where(id: record[:id]).delete
      end
    end

    self[:access_rights].where(group: 'cameras').each do |record|
      user = self[:users].where(username: record[:scope]).first
      if !user.nil?
        self[:cameras].where(owner_id: user[:id]).each do |camera|
          self[:access_rights].insert(token_id:   record[:token_id],
                                      camera_id:  camera[:id],
                                      status:     1,
                                      right:      'snapshot',
                                      created_at: record[:created_at],
                                      updated_at: record[:updated_at],
                                      group:      'N/A',
                                      scope:      'N/A')
        end
        self[:access_rights].where(id: record[:id]).delete
      else
        STDERR.puts "Unable to find a user with a user name of '#{record[:scope]}', deleting record."
        self[:access_rights].where(id: record[:id]).delete
      end
    end

    alter_table(:access_rights) do
      drop_column :group
      drop_column :scope
      set_column_not_null :camera_id
      add_index :camera_id
      add_index :token_id
      add_index [:token_id, :camera_id, :right], unique: true
    end
  end

  down do
    raise "*** THIS MIGRATION CANNOT BE REVERSED."
  end

end