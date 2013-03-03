
APPS = { 
  'pzks'                => { :rails_root => '/home/dev1002/www/current',
                                 :unicorn_bin => '/home/dev1002/.rvm/bin/pzks_unicorn_rails'},
}

DJ_APPS = {
}

def generic_monitoring(w, options)
  cpu_limit = options[:cpu_limit] || 10.percent
  memory_limit = options[:memory_limit] || 20.megabytes

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = memory_limit
      c.times = [3, 5] # 3 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = cpu_limit
      c.times = 5
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end

def unicorn_monitor(w, options)
  rails_env = options[:rails_env] || 'production'

  # unicorn needs to be run from the rails root
  w.start = "cd #{options[:rails_root]} && #{options[:unicorn_bin]} -c #{options[:rails_root]}/config/unicorn.rb -E #{rails_env} -D"

  # QUIT gracefully shuts down workers
  w.stop = "kill -QUIT `cat #{options[:rails_root]}/tmp/pids/unicorn.pid`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{options[:rails_root]}/tmp/pids/unicorn.pid`"

  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  w.pid_file = "#{options[:rails_root]}/tmp/pids/unicorn.pid"
end

def delayed_job_monitor(w, options)
  # retart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 200.megabytes
      c.times = 2
    end
  end

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end
  
    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end

APPS.each do |name, options|
  God.watch do |w|
    w.name     = "rails_#{name}"
    w.group    = name
    w.interval = 30.seconds # default

    unicorn_monitor(w, options)

    generic_monitoring(w, options)
  end
end

DJ_APPS.each do |name, options|
  God.watch do |w|
    w.pid_file    = "#{options[:rails_root]}/tmp/pids/delayed_job.pid"

    dj_cmd_prefix = "#{options[:ruby_bin]} #{options[:rails_root]}/script/delayed_job"

    w.name        = "dj_#{name}"
    w.group       = name
    w.interval    = 30.seconds

    w.start       = "#{dj_cmd_prefix} start"

    w.stop        = "kill -QUIT `cat #{options[:rails_root]}/tmp/pids/delayed_job.pid`"
    w.restart     = "kill -USR2 `cat #{options[:rails_root]}/tmp/pids/delayed_job.pid`"

    delayed_job_monitor(w, options)
  end
end

# This will ride alongside god and kill any rogue memory-greedy
# processes. Their sacrifice is for the greater good.

unicorn_worker_memory_limit = 40_000

Thread.new do
  loop do
    begin
      # unicorn workers
      #
      # ps output line format:
      # 31580 275444 unicorn_rails worker[15] -c /data/github/current/config/unicorn.rb -E production -D
      # pid ram command

      lines = `ps -e -www -o pid,rss,command | grep '[u]nicorn_rails worker'`.split("\n")
      lines.each do |line|
        parts = line.split(' ')
        if parts[1].to_i > unicorn_worker_memory_limit
          # tell the worker to die after it finishes serving its request
          ::Process.kill('QUIT', parts[0].to_i)
        end
      end
    rescue Object
      # don't die ever once we've tested this
      nil
    end

    sleep 30
  end
end
