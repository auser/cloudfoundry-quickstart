default[:redis][:version]   = "2.2.2"
default[:redis][:checksum]  = "a64c32f37e67bdeabbab74f8413a960a8d42e381"
default[:redis][:source]    = "http://redis.googlecode.com/files/redis-#{redis[:version]}.tar.gz"
default[:redis][:bins]      = %w(redis-benchmark redis-cli redis-server mkreleasehdr.sh redis-check-aof redis-check-dump)

default[:redis][:dir]       = "/opt/redis-#{redis[:version]}"
default[:redis][:datadir]   = "/var/db/redis"
default[:redis][:config]    = "/etc/redis.conf"
default[:redis][:logfile]   = "/var/log/redis.log"
default[:redis][:pidfile]   = "/var/run/redis.pid"

default[:redis][:port]        = 6379
default[:redis][:timeout]     = 300
default[:redis][:databases]   = 16
default[:redis][:maxmemory]   = nil
default[:redis][:snapshots]   = {
  900 => 1,
  300 => 10,
  60  => 10000
}

default[:redis][:dbfilename]   = "redis_state.rdb"
default[:redis][:bind_address] = "0.0.0.0"
default[:redis][:unixsocket]   = false
default[:redis][:loglevel]     = "notice"

default[:redis][:syslog_enabled]  = false
default[:redis][:syslog_ident]    = 'redis'
default[:redis][:syslog_facility] = 'local0'

default[:redis][:slaveof]                = nil
default[:redis][:password]               = nil
default[:redis][:slave_serve_stale_data] = true

default[:redis][:maxmemory_policy]  = 'volatile-lru'
default[:redis][:maxmemory_samples] = 3

default[:redis][:appendonly]                = true
default[:redis][:appendfilename]            = 'appendonly.aof'
default[:redis][:appendfsync]               = 'everysec'
default[:redis][:no_appendfsync_on_rewrite] = false

default[:redis][:command_renames] = {}

default[:redis][:vm_enabled]     = false
default[:redis][:vm_swap_file]   = '/tmp/redis.swap'
default[:redis][:vm_max_memory]  = 0
default[:redis][:vm_page_size]   = 32
default[:redis][:vm_pages]       = 134217728
default[:redis][:vm_max_threads] = 4

default[:redis][:hash_max_zipmap_entries]  = 512
default[:redis][:hash_max_zipmap_value]    = 64
default[:redis][:list_max_ziplist_entries] = 512
default[:redis][:list_max_ziplist_value]   = 64
default[:redis][:set_max_intset_entries]   = 512
default[:redis][:activerehashing]          = true
