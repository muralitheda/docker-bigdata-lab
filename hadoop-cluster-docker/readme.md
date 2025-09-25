
# 🚀 Standalone Hadoop Cluster on Docker

## 1. 📂 Project Setup

```bash
mkdir hadoop-cluster-docker
cd hadoop-cluster-docker
```

---

## 2. ⚙️ Environment File (`hadoop.env`)

```env
CLUSTER_NAME=hadoop-datalake
```

---

## 3. 🐳 Docker Compose File (`docker-compose.yml`)

This runs **Namenode, Datanode, ResourceManager, NodeManager**.

```yaml
version: "3"

services:
  namenode:
    image: bde2020/hadoop-namenode:2.0.0-hadoop2.7.4-java8
    container_name: namenode
    restart: always
    ports:
      - "9870:9870"   # HDFS Web UI
      - "9000:9000"   # HDFS RPC
    environment:
      - CLUSTER_NAME=${CLUSTER_NAME}
    volumes:
      - namenode:/hadoop/dfs/name
    platform: linux/amd64

  datanode:
    image: bde2020/hadoop-datanode:2.0.0-hadoop2.7.4-java8
    container_name: datanode
    restart: always
    ports:
      - "9864:9864"   # Datanode Web UI
    environment:
      - SERVICE_PRECONDITION=namenode:9870
    volumes:
      - datanode:/hadoop/dfs/data
    platform: linux/amd64

  resourcemanager:
    image: bde2020/hadoop-resourcemanager:2.0.0-hadoop2.7.4-java8
    container_name: resourcemanager
    restart: always
    ports:
      - "8088:8088"   # YARN ResourceManager UI
    environment:
      - SERVICE_PRECONDITION=namenode:9870 datanode:9864
    platform: linux/amd64

  nodemanager:
    image: bde2020/hadoop-nodemanager:2.0.0-hadoop2.7.4-java8
    container_name: nodemanager
    restart: always
    ports:
      - "8042:8042"   # NodeManager UI
    environment:
      - SERVICE_PRECONDITION=resourcemanager:8088
    platform: linux/amd64

  historyserver:
    image: bde2020/hadoop-historyserver:2.0.0-hadoop2.7.4-java8
    container_name: historyserver
    restart: always
    ports:
      - "8188:8188"   # Job History UI
    volumes:
      - historyserver:/hadoop/yarn/timeline
    environment:
      - SERVICE_PRECONDITION=resourcemanager:8088 nodemanager:8042
    platform: linux/amd64

volumes:
  namenode:
  datanode:
  historyserver:
```

---

## 4. ▶️ Start the Cluster

```bash
docker-compose --env-file hadoop.env up -d
```

Check running services:

```bash
docker ps
```

---

## 5. 🌐 Web UIs

* **HDFS Namenode UI** → [http://localhost:9870](http://localhost:9870)
* **Datanode UI** → [http://localhost:9864](http://localhost:9864)
* **YARN ResourceManager UI** → [http://localhost:8088](http://localhost:8088)
* **NodeManager UI** → [http://localhost:8042](http://localhost:8042)
* **Job History UI** → [http://localhost:8188](http://localhost:8188)

---

## 6. 📦 Access Hadoop CLI

Enter the Namenode container:

```bash
docker exec -it namenode bash
```

Run some HDFS commands:

```bash
hdfs dfs -mkdir -p /datalake/raw
hdfs dfs -mkdir -p /datalake/curated
hdfs dfs -mkdir -p /datalake/gold

echo "Hello Data Lake" > hello.txt
hdfs dfs -put hello.txt /datalake/raw/
hdfs dfs -ls /datalake/raw
```

---

## 7. ✅ Practice Data Lake Concepts

Now we can:

* Create **zones** (`raw`, `curated`, `gold`)
* Test **ingestion** (`hdfs dfs -put`)
* Try **partitioning** directories by date/source
* Explore **file formats** (CSV, Parquet, ORC)

---

This setup is **lightweight Hadoop only**, ideal for **Data Lake exercises** without Hive/Spark overhead.

---
