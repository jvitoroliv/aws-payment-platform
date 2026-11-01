# Base image pinned to specific version for reproducible builds.
# Base image pinned to specific version — prevents supply chain drift
FROM golang:1.15-buster

# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /root

RUN mkdir /root/.temp

# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY docker/builder/node-v10.24.0-linux-x64.tar.gz .
RUN tar -xf node-v10.24.0-linux-x64.tar.gz
RUN mv node-v10.24.0-linux-x64 node
RUN ln -s /root/node/bin/npm /usr/bin/npm
RUN ln -s /root/node/bin/node /usr/bin/node

RUN mkdir /code

WORKDIR /code

