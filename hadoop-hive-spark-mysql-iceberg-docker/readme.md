👍 **High level steps**

* Set up **Hadoop + Hive + Spark + Iceberg** on Docker (Mac M1/M2 compatible).
* Ensure **HiveServer2 auto-starts**.
* Use **Spark instead of MR** for Hive execution.
* Show how to **test Iceberg table functionality** end-to-end.

---

# 🚀 Hive + Spark + Iceberg on Docker (Mac M1/M2)

## 1. 📂 Project Setup

```bash
mkdir hadoop-hive-spark-mysql-iceberg-docker
cd hadoop-hive-spark-mysql-iceberg-docker
```

Create two files:

* `docker-compose.yml`
* `hadoop-hive.env`

---

## 2. ⚙️ Environment File (`hadoop-hive.env`)

```env
HADOOP_HOME=/opt/hadoop
HIVE_HOME=/opt/hive
SPARK_HOME=/opt/spark
HIVE_CONF_DIR=/opt/hive/conf
HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
```

---

## 3. 🐳 Docker Compose File (`docker-compose.yml`)

```yaml
services:
  namenode:
    image: bde2020/hadoop-namenode:2.0.0-hadoop2.7.4-java8
    container_name: namenode
    restart: always
    ports:
      - "9870:9870"
      - "9000:9000"
    volumes:
      - namenode:/hadoop/dfs/name
    environment:
      - CLUSTER_NAME=test
    platform: linux/amd64

  datanode:
    image: bde2020/hadoop-datanode:2.0.0-hadoop2.7.4-java8
    container_name: datanode
    restart: always
    ports:
      - "9864:9864"
    volumes:
      - datanode:/hadoop/dfs/data
    environment:
      - SERVICE_PRECONDITION=namenode:9870
    platform: linux/amd64

  hive-metastore-postgresql:
    image: bde2020/hive-metastore-postgresql:2.3.0
    container_name: hive-metastore-postgresql
    restart: always
    platform: linux/amd64

  hive-metastore:
    image: bde2020/hive:2.3.2-postgresql-metastore
    container_name: hive-metastore
    restart: always
    environment:
      SERVICE_NAME: metastore
      HIVE_METASTORE_URI: thrift://hive-metastore:9083
    depends_on:
      - hive-metastore-postgresql
    ports:
      - "9083:9083"
    platform: linux/amd64

  hive-server:
    image: bde2020/hive:2.3.2-postgresql-metastore
    container_name: hive-server
    restart: always
    environment:
      SERVICE_NAME: hiveserver2
      HIVE_METASTORE_URI: thrift://hive-metastore:9083
    depends_on:
      - hive-metastore
    ports:
      - "10000:10000"
    platform: linux/amd64

  spark-master:
    image: bitnami/spark:3.3.2
    container_name: spark-master
    environment:
      - SPARK_MODE=master
    ports:
      - "7077:7077"
      - "8080:8080"
    platform: linux/amd64

  spark-worker:
    image: bitnami/spark:3.3.2
    container_name: spark-worker
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
    depends_on:
      - spark-master
    ports:
      - "8081:8081"
    platform: linux/amd64

volumes:
  namenode:
  datanode:
```

---

## 4. ▶️ Start the Cluster

```bash
docker-compose up -d
```

Verify containers:

```bash
docker ps
```

Check HiveServer2 logs:

```bash
docker logs hive-server
```

---

## 5. 🐝 Connect to Hive

### From host:

```bash
beeline -u jdbc:hive2://127.0.0.1:10000
```

### From inside hive-server:

```bash
docker exec -it hive-server bash
beeline -u jdbc:hive2://localhost:10000
```

---

## 6. ⚡ Use Spark as Execution Engine

Run inside `hive-server`:

```sql
SET hive.execution.engine=spark;
```

Make this permanent by adding to `hive-site.xml` (`/opt/hive/conf/`):

```xml
<property>
  <name>hive.execution.engine</name>
  <value>spark</value>
</property>
```

---

## 7. ❄️ Create & Test Iceberg Table

### Enable Iceberg in Hive

Add to `hive-site.xml`:

```xml
<property>
  <name>iceberg.engine.hive.enabled</name>
  <value>true</value>
</property>
```

Restart `hive-server` after editing.

### Create Iceberg Table

```sql
CREATE TABLE customers_iceberg (
  id BIGINT,
  name STRING,
  email STRING
) USING ICEBERG;
```

### Insert Data

```sql
INSERT INTO customers_iceberg VALUES (1, 'Alice', 'alice@example.com');
INSERT INTO customers_iceberg VALUES (2, 'Bob', 'bob@example.com');
```

### Query Data

```sql
SELECT * FROM customers_iceberg;
```

### Time Travel

```sql
SELECT * FROM customers_iceberg /* SNAPSHOT_ID 'xyz' */;
```

### Schema Evolution

```sql
ALTER TABLE customers_iceberg ADD COLUMNS (age INT);
```

---

## 8. 🔍 Validation

* Spark UI → `http://localhost:8080`
* HDFS Namenode UI → `http://localhost:9870`
* HiveServer2 (Beeline) working on `jdbc:hive2://127.0.0.1:10000`

---

