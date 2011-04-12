listen '/var/run/engineyard/unicorn_SeattlesBest.sock', :backlog => 2048

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
