Sequel.migration do
  up do
    self.run("alter table access_rights drop constraint access_rights_token_id_fkey")
    self.run("alter table access_rights add constraint access_rights_token_id_fkey "\
             "foreign key (token_id) references access_tokens(id) on delete cascade")
    self.run("alter table cameras drop constraint fk_streams_owner_id")
    self.run("alter table cameras add constraint fk_streams_owner_id "\
             "foreign key (owner_id) references users(id) on delete cascade")
  end

  down do
    self.run("alter table access_rights drop constraint access_rights_token_id_fkey")
    self.run("alter table access_rights add constraint access_rights_token_id_fkey "\
             "foreign key (token_id) references access_tokens(id) on delete restrict")
    self.run("alter table cameras drop constraint fk_streams_owner_id")
    self.run("alter table cameras add constraint fk_streams_owner_id "\
             "foreign key (owner_id) references users(id) on delete restrict")
  end
end

