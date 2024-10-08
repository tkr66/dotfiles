FROM ubuntu:latest

RUN apt update && \
      apt install -y --no-install-recommends \
        make \
        sudo
