

# 🚀 Quickstart: Hadoop + Hive (with Spark) + MySQL + Iceberg on MacBook Pro M4

---

## 1️⃣ Install Docker Desktop (Apple Silicon / M4)

1. Download Docker Desktop for Mac (Apple chip):
   👉 [https://docs.docker.com/desktop/install/mac/](https://docs.docker.com/desktop/install/mac/)

2. Install it and start Docker.

3. Verify in terminal:

   ```bash
   docker --version
   docker compose version
   ```

---

## 2️⃣ Create a Project Folder

```bash
mkdir hive-lab
cd hive-lab
```

---

## 3️⃣ Create `docker-compose.yml`

Create a file `docker-compose.yml` in this folder:

```yaml
version: "3.9"
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: metastore
      MYSQL_USER: hive
      MYSQL_PASSWORD: hive
    ports:
      - "3306:3306"

  namenode:
    image: apache/hadoop:3
    command: ["namenode"]
    ports:
      - "9870:9870"

  datanode:
    image: apache/hadoop:3
    command: ["datanode"]
    ports:
      - "9864:9864"

  hive-metastore:
    image: apache/hive:3.1.3
    environment:
      SERVICE_NAME: metastore
      HIVE_METASTORE_DB_HOST: mysql
      HIVE_METASTORE_DB_NAME: metastore
      HIVE_METASTORE_DB_USER: hive
      HIVE_METASTORE_DB_PASS: hive
    depends_on:
      - mysql
    ports:
      - "9083:9083"

  hive-server:
    image: apache/hive:3.1.3
    environment:
      SERVICE_NAME: hiveserver2
      HIVE_METASTORE_URI: thrift://hive-metastore:9083
    depends_on:
      - hive-metastore
    ports:
      - "10000:10000" # HiveServer2
      - "10002:10002" # Beeline

  spark:
    image: bitnami/spark:3.5
    environment:
      - SPARK_MODE=master
    ports:
      - "7077:7077"
      - "8080:8080"
```

👉 These images (`mysql`, `apache/hadoop`, `apache/hive`, `bitnami/spark`) are **multi-arch**, so they’ll run on your M4 without rebuilding.

---

## 4️⃣ Start the Cluster

Run:

```bash
docker compose up -d
```

Check running containers:

```bash
docker ps
```

---

## 5️⃣ Connect to Hive

1. Enter HiveServer2:

   ```bash
   docker exec -it hive-lab-hive-server-1 bash
   ```

2. Start Beeline:

   ```bash
   beeline -u "jdbc:hive2://localhost:10000"
   ```

3. Run a quick query:

   ```sql
   SHOW DATABASES;
   ```

---

## 6️⃣ (Optional) Create an Iceberg Table

Inside Beeline:

```sql
CREATE TABLE iceberg_table (
  id BIGINT,
  name STRING
)
USING iceberg;
```

---

## 7️⃣ Web UIs

* Hadoop NameNode: [http://localhost:9870](http://localhost:9870)
* Spark Master: [http://localhost:8080](http://localhost:8080)

---

## 8️⃣ Stop the Cluster

```bash
docker compose down -v
```

---

✅ That’s it! Now we have Hadoop + Hive + Spark + MySQL + Iceberg running in Docker on your **Mac M4** with **just one `docker-compose.yml` file**.

