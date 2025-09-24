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