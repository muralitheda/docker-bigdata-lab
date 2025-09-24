#!/bin/bash
set -e

# Format the namenode if it's the first time
if [ ! -d "/tmp/hadoop-root/dfs/name/current" ]; then
  hdfs namenode -format
fi

# Start the cluster
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Wait for HDFS to be ready
echo "Waiting for HDFS to be ready..."
sleep 10
hdfs dfs -mkdir -p /user/hive/warehouse

# Start Metastore and HiveServer2
/opt/hive/bin/schematool -dbType mysql -initSchema || echo "Schema already initialized"
/opt/hive/bin/hive --service metastore &
/opt/hive/bin/hive --service hiveserver2 &

# Keep the container running indefinitely
tail -f /dev/null
