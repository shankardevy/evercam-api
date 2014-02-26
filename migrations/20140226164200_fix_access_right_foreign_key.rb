Sequel.migration do

  up do
    self.run("alter table access_rights drop constraint access_rights_camera_id_fkey")
    self.run("alter table access_rights add constraint access_rights_camera_id_fkey "\
             "foreign key (camera_id) references cameras(id) on delete cascade")
  end

  down do
    self.run("alter table access_rights drop constraint access_rights_camera_id_fkey")
    self.run("alter table access_rights add constraint access_rights_camera_id_fkey "\
             "foreign key (camera_id) references cameras(id) on delete restrict")
  end

end

