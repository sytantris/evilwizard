require 'charged/mina'

# charged deployment script
#
# Add server blocks for your production server and any others
# (staging, etc). Configure the paths to match your setup, as well
# as the scripts in config/deploy/ for god, unicorn, etc.
#
# Then to set up the remote server, run:
#
# $ bundle exec mina setup         # set up shared paths on server
# $ bundle exec mina setup:db      # configure remote config/database.yml
#
# To set up a crontab, add/edit config/deploy/crontab.erb and run:
#
# $ bundle exec mina setup:crontab # install crontab
#                                  # (from config/deploy/crontab.erb)
#
# And to deploy (to=production and branch=master are defaults):
# $ bundle exec mina deploy to=production branch=master

set :user, ENV['user'] || ENV['USER']
set :app, 'EvilWizard'

set :repository, ENV['repo'] || 'git@github.com:sytantris/evilwizard.git'
set :branch, ENV['branch'] || 'master'

##
# server definitions
# invoke mina like `mina deploy to=stage` to change server
# default is production
server :production do
  set :domain, 'evilwizard.ca'
  set :rails_env, ENV['RAILS_ENV'] || 'production'
  set :forward_agent, true
end

##
# Path configuration:
#
# Uncomment and change these if you want, defaults should work.
#
# set :deploy_to_prefix, "/var/www"
# set :deploy_to, proc { "#{deploy_to_prefix}/#{app}" }
#
# set :log_path, proc { "#{deploy_to}/#{shared_path}/log" }
# set :tmp_path, proc { "#{deploy_to}/#{shared_path}/tmp" }
# set :pid_path, proc { "#{tmp_path}/pids" }
# set :socket_path, proc { "#{tmp_path}/sockets" }
# set :config_path, proc { "#{deploy_to}/#{shared_path}/config" }
#
# Local Paths to configuration files and templates, these are rendered
# and copied to the server:
#
# set :nginx_conf_template, "config/deploy/nginx.conf.erb"
# set :database_yml_template, "config/deploy/database.yml.erb"
# set :unicorn_god_conf, "config/deploy/unicorn.god"
#
# set :cron_email, ""
# set :crontab_template, "config/deploy/crontab.erb"

##
# Shared paths:
#
# These paths are symlinked from the shared/ directory into the
# app, replacing any paths from the release, and are preserved
# between deploys:
set :shared_paths, ['log', 'tmp', 'config/database.yml', '.env']

# These paths are created when you run `mina setup`:
set :setup_paths, [log_path, tmp_path, pid_path, socket_path, config_path]

##
# RefineryCMS:
#
# If you're using refinerycms, uncomment the following lines:
#
# set :refinery_uploads_path, "#{deploy_to}/shared/public/system/refinery"
# shared_paths << 'public/system/refinery'
# setup_paths << refinery_uploads_path

##
# How many releases to keep?
# set :keep_releases, 10


# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # invoke :'rbenv:load'
end

# tasks to run during `mina setup`
task :setup => :environment do
  invoke :'setup:shared_paths'
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'

    # generates and links nginx and god config
    invoke :'deploy:config'

    to :launch do
      invoke :'unicorn:restart'
    end
  end
end
