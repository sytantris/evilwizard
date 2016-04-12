# vim: :ft=ruby:

env ||= {}
env['RAILS_ENV'] ||= 'production'
env['WEB_CONCURRENCY'] ||= 2

APP = File.expand_path('../../..', __FILE__)

God.watch do |w|
  pid_file = File.join(APP, 'tmp/pids/unicorn.pid')

  w.name = File.basename(File.dirname(APP))
  w.dir = APP
  w.interval = 60.seconds
  w.start = "cd #{APP}; /usr/local/bin/bundle exec unicorn -c #{APP}/config/deploy/unicorn.rb -D"
  w.stop = "kill -s QUIT $(cat #{pid_file})"
  w.restart = "cd #{APP} && bash config/deploy/restart-unicorn.sh"
  w.start_grace = 20.seconds
  w.restart_grace = 20.seconds
  w.pid_file = pid_file
  w.log = "#{APP}/log/unicorn.god.log"

  w.uid = 'deployer'
  w.gid = 'web'

  if File.exists? "#{APP}/.env"
    begin
      require 'dotenv'
      w.env = Dotenv.load("#{APP}/.env").merge(env)
    rescue LoadError
    end
  else
    w.env = env
  end

  w.behavior :clean_pid_file

  w.start_if do |start|
    start.condition(:process_running) do |c|
      # check if daemon is running every 10 seconds
      c.interval = 10.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      # pick five memory usage at different times
      # if three of them are above memory limit
      # then we restart the daemon
      c.above = 256.megabytes
      c.times = [3, 5]
    end

    restart.condition(:cpu_usage) do |c|
      # restart daemon if cpu usage goes above 90% > 5 times
      c.above = 90.percent
      c.times = 5
    end
  end

  w.lifecycle do |on|
    # handle edge cases where daemon can't start for some reason
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart] # If God tries to start or restart
      c.times = 5                     # five times
      c.within = 5.minutes            # within five minutes
      c.transition = :unmonitored     # stop trying to monitor
      c.retry_in = 10.minutes         # for 10 minutes and then monitor again
      c.retry_times = 5               # try this up to five times
      c.retry_within = 2.hours        # and give up if flapping 5 times in 2hrs
    end
  end

end
