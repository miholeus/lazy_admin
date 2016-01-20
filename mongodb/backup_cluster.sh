


# back up a sharded cluster

mongo --host some_mongos --eval "sh.stopBalancer()"
# make sure it worked!

# back up config database / a config server
mongodump --host some_mongos_or_some_config_server --db config /backups/cluster1/configdb

# back up all shards
mongodump --host shard1_svr --oplog /backups/cluster1/shard1
mongodump --host shard2_svr --oplog /backups/cluster1/shard2
mongodump --host shard3_svr --oplog /backups/cluster1/shard3
mongodump --host shard4_svr --oplog /backups/cluster1/shard4
mongodump --host shard5_svr --oplog /backups/cluster1/shard5
mongodump --host shard6_svr --oplog /backups/cluster1/shard6

# balancer back on
mongo --host some_mongos --eval "sh.startBalancer()"
