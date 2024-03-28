# Kafka ROCK

[![Release](https://github.com/canonical/kafka-rock/actions/workflows/publish.yaml/badge.svg)](https://github.com/canonical/zookeeper-rock/actions/workflows/publish.yaml)
[![Container Registry](https://img.shields.io/badge/Container%20Registry-published-blue)](https://github.com/canonical/kafka-rock/pkgs/container/kafka)

This repository contains the packaging metadata for creating a ROCK of Zookeeper built from Canonical Kafka release artifacts.  For more information on ROCKs, visit the [rockcraft Github](https://github.com/canonical/rockcraft). 

## Building the ROCK
The steps outlined below are based on the assumption that you are building the ROCK with the latest LTS of Ubuntu.  If you are using another version of Ubuntu or another operating system, the process may be different.

### Clone Repository
```bash
git clone git@github.com:canonical/kafka-rock.git
cd kafka-rock
```

### Installing Prerequisites
```bash
sudo snap install rockcraft --edge
sudo snap install docker
sudo snap install lxd
sudo snap install skopeo --edge --devmode
```

### Configuring Prerequisites
```bash
sudo usermod -aG docker $USER 
sudo lxd init --auto
```
*_NOTE:_* You will need to open a new shell for the group change to take effect (i.e. `su - $USER`)

### Packing and Running the ROCK
```bash
rockcraft pack
sudo skopeo --insecure-policy copy oci-archive:kafka*.rock docker-daemon:<username>/kafka:<tag>
docker run --rm -it <username>/kafka:<tag>
```
## License
The Kafka ROCK is free software, distributed under the Apache
Software License, version 2.0. See
[LICENSE](https://github.com/canonical/zookeeper-rock/blob/3.6/stable/LICENSE)
for more information.
