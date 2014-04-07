require 'bcrypt'

Sequel.migration do

  up do
    password = BCrypt::Password.create("K0l27B2iLR63F0L5d3Wz").to_s
    country  = self[:countries][iso3166_a2: 'ie']
    if !country.nil?
      self[:users].insert(forename:     'Evercam',
                          lastname:     'Admin',
                          username:     'evercam',
                          password:     password,
                          country_id:   country[:id],
                          confirmed_at: Time.now,
                          email:        'howrya@evercam.io',
                          created_at:   Time.now,
                          updated_at:   Time.now)
    else
      STDERR.puts "WARNING: Unable to create the evercam user in the #{self.uri} "\
                  "database as Ireland could not be found in the countries table."
    end
  end

  down do
    self[:users].where(username: 'evercam').delete
  end

end

