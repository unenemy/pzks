
RAILS_ENV  = ENV['RAILS_ENV'] || 'production'
RAILS_ROOT = ENV['RAILS_ROOT'] || File.expand_path(File.dirname(File.dirname(__FILE__)))

worker_processes (RAILS_ENV == 'production' ? 2 : 2)

# Help ensure your application will always spawn in the symlinked "current" directory that Capistrano sets up
working_directory "/home/dev1002/www/current"

listen '/home/dev1002/www/current/tmp/sockets/unicorn.sock', :backlog => 2048

# Nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

pid "/home/dev1002/www/current/tmp/pids/unicorn.pid"

# Logs are very useful for trouble shooting, use them
stderr_path "/home/dev1002/www/current/log/unicorn.stderr.log"
stdout_path "/home/dev1002/www/current/log/unicorn.stdout.log"

# Use "preload_app true"
preload_app true

GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|

  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # Thank you GitHub!
  #
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  # Using this method we get 0 downtime deploys.

  old_pid = RAILS_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    # someone else did our job for us
    end
  end

end

after_fork do |server, worker|

  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  # the following is *required* for Rails + "preload_app true"

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis. TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)

  # Unicorn master is started as root, which is fine, but let's
  # drop the workers to your user/group
  begin
    uid, gid = Process.euid, Process.egid
    user, group = 'dev1002', 'dev1002'
    target_uid = Etc.getpwnam(user).uid
    target_gid = Etc.getgrnam(group).gid
    worker.tmp.chown(target_uid, target_gid)
    if uid != target_uid || gid != target_gid
      Process.initgroups(user, target_gid)
      Process::GID.change_privilege(target_gid)
      Process::UID.change_privilege(target_uid)
    end
  rescue => e
    if RAILS_ENV == 'development'
      STDERR.puts "couldn't change user, oh well"
    else
      raise e
    end
  end

end
