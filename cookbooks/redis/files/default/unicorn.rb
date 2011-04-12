UNICORN_CONF="/data/myapp/shared/config/custom_unicorn.rb"
current_path = '/data/SeattlesBest/current'
shared_path = '/data/SeattlesBest/shared'
shared_bundler_gems_path = "/data/SeattlesBest/shared/bundler_gems"

working_directory '/data/SeattlesBest/current/'
worker_processes 24
listen '/var/run/engineyard/unicorn_SeattlesBest.sock', :backlog => 2048
timeout 60
pid "/var/run/engineyard/unicorn_SeattlesBest.pid"

# Based on http://gist.github.com/206253

logger Logger.new("log/unicorn.log")

# Load the app into the master before forking workers for super-fast worker spawn times
preload_app true

# some applications/frameworks log to stderr or stdout, so prevent
# them from going to /dev/null when daemonized here:
stderr_path "log/unicorn.stderr.log"
stdout_path "log/unicorn.stdout.log"

# REE - http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_fork do |server, worker|

  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.
  old_pid = "#{server.config[:pid]}.oldbin"

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :TERM : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
  sleep 1
end

if defined?(Bundler.settings)
  before_exec do |server|
    paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR) 
    paths.unshift "#{shared_bundler_gems_path}/bin"
    ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

    ENV['GEM_HOME'] = ENV['GEM_PATH'] = shared_bundler_gems_path
    ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
  end
end

after_fork do |server, worker|
  worker_pid = File.join(File.dirname(server.config[:pid]), "unicorn_worker_SeattlesBest_#{worker.nr}.pid")
  File.open(worker_pid, "w") { |f| f.puts Process.pid }
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

  if defined?(Redis)
    if File.exists? '/data/homedirs/deploy/instances.yml' # EngineYard
      $redis = Redis.new(:host => YAML.load_file('/data/homedirs/deploy/instances.yml').find{|i| i['name'] == 'redis'}['private_hostname'], :port => 6379)
    else
      $redis = Redis.new(:host => 'localhost', :port => 6379)
    end
  end
end
