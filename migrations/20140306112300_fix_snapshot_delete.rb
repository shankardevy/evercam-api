Sequel.migration do

  up do
    self.run("alter table snapshots drop constraint snapshots_camera_id_fkey")
    self.run("alter table snapshots add constraint snapshots_camera_id_fkey "\
             "foreign key (camera_id) references cameras(id) on delete cascade")
  end

  down do
    self.run("alter table snapshots drop constraint snapshots_camera_id_fkey")
    self.run("alter table snapshots add constraint snapshots_camera_id_fkey "\
             "foreign key (camera_id) references cameras(id) on delete restrict")
  end

end

