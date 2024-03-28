#!/bin/bash

KAFKA_IMAGE=$1

if [ -z "$KAFKA_IMAGE" ]; then KAFKA_IMAGE="kafka:latest"; fi

function setup() {
  echo "Setting up Environment ..."

  # Check that docker is working
  DOCKER_VERSION=$(docker --version)

  if [ -z "$DOCKER_VERSION" ];
  then
    echo "Docker not installed!"
    exit 1
  else
    echo "Docker version: $DOCKER_VERSION"
  fi

  # Check that docker is working
  YQ_VERSION=$(yq --version)

  if [ -z "$YQ_VERSION" ];
  then
    echo "YQ not installed!"
    exit 1
  else
    echo "YQ version: $YQ_VERSION"
  fi

  # Create Kafka network
  docker network create -d bridge kafka-network > /dev/null
}

function start_zookeeper() {
  echo "Start ZooKeeper ..."

  # Start ZooKeeper
  docker run -d \
    --rm --network kafka-network --name zookeeper \
    ubuntu/zookeeper:3.8-22.04_edge > /dev/null

  sleep 5
}

function start_kafka_vanilla() {
  echo "Start Kafka ..."

  docker run -d \
    --rm --name kafka --network kafka-network -p 9092:9092 \
    $KAFKA_IMAGE > /dev/null

  sleep 5
}

function start_kafka_with_ip() {
  echo "Start Kafka ..."

  ZK_IP=$(docker network inspect kafka-network | yq '.[0].Containers | map(select(.Name == "zookeeper")) | .[0].IPv4Address')

  echo "Using ZooKeeper IP: $ZK_IP"

  docker run -d \
    --rm --name kafka --network kafka-network -p 9092:9092 \
    -e ZOOKEEPER_HOST=$ZK_IP $KAFKA_IMAGE > /dev/null
}

function is_in() {
    [[ $2 =~ (^|[[:space:]])$1($|[[:space:]]) ]] && return || exit 1
}

function is_not_in() {
    [[ $2 =~ (^|[[:space:]])$1($|[[:space:]]) ]] && exit 1 || return
}


function checks() {

  echo "Sanity Checks ..."

  TOPIC_NAME=$1

  VERSION=$(docker exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --version)

  echo "Kafka Version: ${VERSION}"

  TOPICS=$(docker exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
    --list)

  is_not_in $TOPIC_NAME "$TOPICS"

  echo "Creating topics"

  docker exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
    --topic $TOPIC_NAME --create

  TOPICS=$(docker exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
    --list)

  echo "Topics: $TOPICS"

  is_in $TOPIC_NAME "$TOPICS"
}

function teardown() {
  docker stop kafka zookeeper
}

function cleanup() {
  docker network rm kafka-network
}

function log() {
    echo "$1"
}

echo "Tests: 2"

setup && (
  log '*** Vanilla Test ***'
  ( start_zookeeper && start_kafka_vanilla && checks my-test && \
  teardown && log '*** SUCCESS ***' ) || ( teardown && log '*** FAILED ***' )
) && (
  log '*** Externally provided ZooKeeper ***'
  ( start_zookeeper && start_kafka_with_ip && checks my-test-2 && \
  teardown && log '*** SUCCESS ***' ) || ( teardown && log '*** FAILED ***' )
) && cleanup || cleanup

