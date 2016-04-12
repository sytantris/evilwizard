# use at least one per core, more will usually help for
# short waits on db/cache
worker_processes Integer(ENV['WEB_CONCURRENCY'] || 2)
timeout 30

APP = ::File.expand_path('../../..', __FILE__)
working_directory APP
listen "#{APP}/tmp/sockets/unicorn.sock", :backlog => 64
pid "#{APP}/tmp/pids/unicorn.pid"
stderr_path "#{APP}/log/unicorn.stderr.log"
stdout_path "#{APP}/log/unicorn.stdout.log"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

# Enable this flag to have unicorn test client connections by writing the
# beginning of the HTTP headers before calling the application.  This
# prevents calling the application for connections that have disconnected
# while queued.  This is only guaranteed to detect clients on the same
# host unicorn runs on, and unlikely to detect disconnects even on a
# fast LAN.
check_client_connection false

# see http://kavassalis.com/2013/04/unicorn-hot-restarts-my-definitive-guide/
before_exec do |server|
  # Make sure it's not looking for the Gemfile it was originally started with
  ENV['BUNDLE_GEMFILE'] = "#{APP}/Gemfile"
end

before_fork do |server, worker|
  # This provides heroku support but there's no harm in having it even if
  # we aren't using heroku. This allows unicorn to be shut down gracefully
  # by signaling TERM as well as the default QUIT.
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  # For preload to work we need to handle connections to other services
  # properly, including Active Record, memcached, etc.
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  # before forking, kill old master if it exists, zero downtime deploys
  old_pid = "#{APP}/tmp/pids/unicorn.pid.oldbin"
  if server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did it
    end
  end
end

after_fork do |server, work|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and ignoring it.'
  end

  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
