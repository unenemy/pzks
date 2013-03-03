
require "rvm/capistrano"
set :rvm_ruby_string, 'ruby-1.9.3-p392@pzks'
set :rvm_type, :user

set :application, "pzks.dev-dev.com"
set :app_process, "pzks"

set :deploy_to, "/home/dev1002/www"
set :deploy_via, :remote_cache
set :keep_releases, 2

set :god_port, "17171"

set :user, "dev1002"
set :use_sudo, false

set :scm, "git"
set :repository,  "git@github.com:unenemy/pzks.git"
set :branch, "master"

role :app, application, :primary => true
role :web, application, :primary => true
ssh_options[:forward_agent] = false

role :db, application, :primary => true
default_run_options[:pty] = true
default_run_options[:shell] = false

set :monitor_binary, "/home/dev1002/.rvm/bin/bootup_god"

namespace :deploy do
  desc "Rename database.yml"
  task :rename_database_yml do
    run "mv #{release_path}/config/database_production.yml #{release_path}/config/database.yml"
  end

  task :init_folders do
    run "mkdir -p #{shared_path}/sockets"
    run "ln -s #{shared_path}/sockets #{release_path}/tmp/sockets"
  end

  task :enable_rvm do
    run "mv #{release_path}/rvmrc #{release_path}/.rvmrc"
    run "rvm rvmrc trust #{release_path}"
  end

  desc "Start application"
  task :start, :roles => :app do
    run "#{monitor_binary} -p #{god_port} -c #{current_path}/config/god.rb"
  end

  desc "Stop application"
  task :stop, :roles => :app do
    run "#{monitor_binary} -p #{god_port} terminate"
  end

  desc "Restart application"
  task :restart, :roles => :app do
    run "#{monitor_binary} -p #{god_port} restart rails_#{app_process}"
  end

  desc "Load assets"
  task :precompile, :roles => :app do
    #run "cd #{release_path}/ && rake assets:precompile"
  end
end

require 'bundler/capistrano'

before "deploy:assets:precompile", "bundle:install"

after 'deploy:update_code', 'deploy:enable_rvm', "deploy:cleanup"
after 'deploy:finalize_update', 'deploy:rename_database_yml'
after 'deploy:create_symlink', 'deploy:init_folders'
after 'deploy:finalize_update', 'deploy:precompile'


# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
