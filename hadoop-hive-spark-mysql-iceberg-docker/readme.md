
### 1️⃣ Project Setup

First, create the necessary project structure.

```bash
mkdir hadoop-hive-spark-mysql-iceberg-docker
cd hadoop-hive-spark-mysql-iceberg-docker
mkdir conf
```

Now, create the following files inside the `conf` directory.

#### `conf/core-site.xml`

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://namenode:9000</value>
    </property>
</configuration>
```

#### `conf/hdfs-site.xml`

```xml
<configuration>
    <property>
        <name>dfs.namenode.rpc-bind-host</name>
        <value>0.0.0.0</value>
    </property>
    <property>
        <name>dfs.namenode.servicerpc-bind-host</name>
        <value>0.0.0.0</value>
    </property>
    <property>
        <name>dfs.datanode.address</name>
        <value>0.0.0.0:9866</value>
    </property>
    <property>
        <name>dfs.datanode.http.address</name>
        <value>0.0.0.0:9864</value>
    </property>
    <property>
        <name>dfs.datanode.https.address</name>
        <value>0.0.0.0:9867</value>
    </property>
    <property>
        <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
        <value>false</value>
    </property>
</configuration>
```

#### `conf/hive-site.xml`

```xml
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://mysql:3306/metastore?createDatabaseIfNotExist=true&amp;useSSL=false&amp;allowPublicKeyRetrieval=true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>hdfs://namenode:9000/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://hive-metastore:9083</value>
    </property>
</configuration>
```

#### `conf/start-cluster.sh`

```bash
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
```

-----

### 2️⃣ Dockerfile

Create a `Dockerfile` in the root of your project directory.

```dockerfile
# Use a compatible base image. Ubuntu is a good choice.
FROM ubuntu:22.04

# Install Java, as the Hadoop base image did not include it.
RUN apt-get update && apt-get install -y openjdk-11-jdk-headless wget curl netcat-openbsd rsync && rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV HADOOP_VERSION="3.3.6"
ENV SPARK_VERSION="3.5.1"
ENV HIVE_VERSION="3.1.3"
ENV ICEBERG_VERSION="1.5.0"
ENV MYSQL_CONNECTOR_VERSION="8.0.33"

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV HADOOP_HOME="/opt/hadoop"
ENV SPARK_HOME="/opt/spark"
ENV HIVE_HOME="/opt/hive"
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$HIVE_HOME/bin

WORKDIR /

# Download and install Hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -xvf hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_HOME && \
    rm hadoop-$HADOOP_VERSION.tar.gz

# Download and install Hive
RUN wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
    tar -xvf apache-hive-$HIVE_VERSION-bin.tar.gz && \
    mv apache-hive-$HIVE_VERSION-bin $HIVE_HOME && \
    rm apache-hive-$HIVE_VERSION-bin.tar.gz

# Download and install Spark
RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.tgz && \
    tar -xvf spark-$SPARK_VERSION-bin-hadoop3.tgz && \
    mv spark-$SPARK_VERSION-bin-hadoop3 $SPARK_HOME && \
    rm spark-$SPARK_VERSION-bin-hadoop3.tgz

# Add Iceberg and MySQL Connector JARs to Hive's lib directory
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-hive-runtime/${ICEBERG_VERSION}/iceberg-hive-runtime-${ICEBERG_VERSION}.jar ${HIVE_HOME}/lib/
ADD https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar ${HIVE_HOME}/lib/

# Copy configuration files
COPY conf/core-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/hive-site.xml ${HIVE_HOME}/conf/
COPY conf/start-cluster.sh /usr/local/bin/

# Final setup
RUN chmod +x /usr/local/bin/start-cluster.sh
RUN mkdir -p /tmp/hadoop/dfs/name /tmp/hadoop/dfs/data && \
    mkdir -p /tmp/spark-events && \
    mkdir -p /user/hive/warehouse

CMD ["/usr/local/bin/start-cluster.sh"]
```

-----

### 3️⃣ Docker Compose File

Create a `docker-compose.yml` file in the root of your project directory.

```yaml
version: "3.9"

services:
  mysql:
    image: mysql:8.0
    container_name: mysql
    hostname: mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: metastore
      MYSQL_USER: hive
      MYSQL_PASSWORD: hive
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      retries: 5

  namenode:
    image: apache/hadoop:3.3.6
    container_name: namenode
    hostname: namenode
    volumes:
      - namenode_data:/tmp/hadoop-root
    ports:
      - "9870:9870"
    command: ["hdfs", "namenode"]

  datanode:
    image: apache/hadoop:3.3.6
    container_name: datanode
    hostname: datanode
    depends_on:
      - namenode
    ports:
      - "9864:9864"
    volumes:
      - datanode_data:/tmp/hadoop-root
    command: ["hdfs", "datanode"]

  hive-metastore:
    build: .
    container_name: hive-metastore
    hostname: hive-metastore
    depends_on:
      - mysql
      - namenode
      - datanode
    volumes:
      - namenode_data:/tmp/hadoop-root
    ports:
      - "9083:9083"
    command: ["/opt/hive/bin/hive", "--service", "metastore"]

  hive-server:
    build: .
    container_name: hive-server
    hostname: hive-server
    depends_on:
      - hive-metastore
    ports:
      - "10000:10000"
      - "10002:10002"
    command: ["/opt/hive/bin/hive", "--service", "hiveserver2"]

volumes:
  namenode_data:
  datanode_data:
```

-----

### 4️⃣ Build and Run the Cluster

1.  **Build the Docker image**:

    ```bash
    docker compose build
    ```

2.  **Start the containers**:

    ```bash
    docker compose up -d
    ```

3.  **Verify services**:

    ```bash
    docker ps
    ```

    Your services should all be up and running.

-----

### 5️⃣ Connect to Hive and Create an Iceberg Table

1.  **Connect to the Hive server**:

    ```bash
    docker exec -it hive-server beeline -u "jdbc:hive2://localhost:10000"
    ```

2.  **Create your Iceberg table**:

    ```sql
    CREATE TABLE iceberg_table (
      id BIGINT,
      name STRING,
      ts TIMESTAMP
    )
    STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
    TBLPROPERTIES ('iceberg.catalog'='hive_prod');
    ```

    Note: For this to work, Spark must be configured to use the Hive catalog. This setup assumes a basic Hive-only interaction.

3.  **Verify the table**:

    ```sql
    SHOW TABLES;
    DESCRIBE FORMATTED iceberg_table;
    ```

-----

### 6️⃣ Stop the Cluster

To stop and clean up all the containers and associated volumes, use the following command:

```bash
docker compose down -v
```