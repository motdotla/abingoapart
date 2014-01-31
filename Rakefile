require 'rubygems'
require 'rake'

namespace :db do
  desc "Auto migrate the database (destroys data)"
  task :automigrate do
    require 'app'
    DataMapper.auto_migrate!
  end

  desc "Auto upgrade the database"
  task :autoupgrade do
    require 'app'
    DataMapper.auto_upgrade!
  end
end