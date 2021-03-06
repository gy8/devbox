FROM debian:jessie
MAINTAINER Guang Yang <garry.yangguang@gmail.com>


RUN apt-get update -y && apt-get install -y \
    curl \
    net-tools \
    unzip \
    python \
    ruby \
    git \
    vim-nox \
    tcpdump \
    screen \
    ruby-dev \
    cmake \
    pkg-config \
    libffi-dev \
    libssl-dev \
    libmysqlclient-dev \
    libkrb5-dev \
    python-dev \
    python-psycopg2 \
    python-matplotlib \
    python-lxml \
    python-scipy \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Get most updated pip
RUN curl -s https://bootstrap.pypa.io/get-pip.py > get-pip.py \
&& python get-pip.py pip==7.1.2

WORKDIR /home/dev
ENV HOME /home/dev

# JAVA
ENV JAVA_HOME /usr/jdk1.8.0_31
ENV PATH $PATH:$JAVA_HOME/bin
RUN curl -sL --retry 3 --insecure \
  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
  "http://download.oracle.com/otn-pub/java/jdk/8u31-b13/server-jre-8u31-linux-x64.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $JAVA_HOME /usr/java \
  && rm -rf $JAVA_HOME/man

# SPARK
ENV SPARK_VERSION 1.4.1
ENV HADOOP_VERSION 2.4
ENV SPARK_PACKAGE $SPARK_VERSION-bin-hadoop$HADOOP_VERSION
ENV SPARK_HOME /usr/spark-$SPARK_PACKAGE
ENV PATH $PATH:$SPARK_HOME/bin
RUN curl -sL --retry 3 \
  "http://mirrors.ibiblio.org/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_PACKAGE.tgz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $SPARK_HOME /usr/spark

# HADOOP/S3
RUN curl -sL --retry 3 "http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.6.0/hadoop-aws-2.6.0.jar" -o $SPARK_HOME/lib/hadoop-aws-2.6.0.jar \
 && curl -sL --retry 3 "http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.14/aws-java-sdk-1.7.14.jar" -o $SPARK_HOME/lib/aws-java-sdk-1.7.14.jar \
 && curl -sL --retry 3 "http://central.maven.org/maven2/com/google/collections/google-collections/1.0/google-collections-1.0.jar" -o $SPARK_HOME/lib/google-collections-1.0.jar \
 && curl -sL --retry 3 "http://central.maven.org/maven2/joda-time/joda-time/2.8.2/joda-time-2.8.2.jar" -o $SPARK_HOME/lib/joda-time-2.8.2.jar

# Spark JDBC
ENV JDBC_DRIVER_JAR postgresql-9.3-1103.jdbc41.jar
RUN curl -o $HOME/$JDBC_DRIVER_JAR https://jdbc.postgresql.org/download/$JDBC_DRIVER_JAR

# Add default configs
ADD bash_profile /home/dev/.bash_profile
ADD gitconfig /home/dev/.gitconfig

# Run vim stuff
ADD vimrc /home/dev/.vimrc
run git clone -q https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
run vim -c 'PluginInstall' -c 'qa!'
run cd ~/.vim/bundle/command-t/ruby/command-t \
 && ruby extconf.rb \
 && make

# Plushy Specific
ADD plushy_requirements.txt /home/dev/plushy_requirements.txt
RUN pip install -r /home/dev/plushy_requirements.txt
ENV PYTHONPATH /home/dev/plushy:$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip
ENV SPARK_MASTER_DNS guang.spark
ENV PLUSHY_VERSION 1.6

# Airflow Specific
RUN git clone https://github.com/gy8/airflow.git $HOME/airflow_dev
RUN cd $HOME/airflow_dev \
 && git checkout feat_postgres_check \
 && pip install -r requirements.txt
Run cd $HOME/airflow_dev \
 &&  python setup.py develop
ENV AIRFLOW_HOME /home/dev/airflow_config

# Cleanup
RUN rm /usr/lib/python2.7/dist-packages/pkg_resources.py*

# Add run.sh for kube

CMD ["tail", "-F", "/etc/hosts"]
