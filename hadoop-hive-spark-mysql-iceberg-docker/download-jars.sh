#!/usr/bin/env bash
set -euo pipefail

ICEBERG_VERSION=1.7.2
SPARK_SUFFIX=3.3_2.12   # matches the bde spark image (Spark 3.3, Scala 2.12)

mkdir -p jars

echo "Downloading Iceberg jars (version $ICEBERG_VERSION) into ./jars/ ..."
curl -fL -o jars/iceberg-hive-runtime-${ICEBERG_VERSION}.jar \
  https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-hive-runtime/${ICEBERG_VERSION}/iceberg-hive-runtime-${ICEBERG_VERSION}.jar

curl -fL -o jars/iceberg-spark-runtime-${SPARK_SUFFIX}-${ICEBERG_VERSION}.jar \
  https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SUFFIX}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SUFFIX}-${ICEBERG_VERSION}.jar

ls -l jars
echo "Done."
