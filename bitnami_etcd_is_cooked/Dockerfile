FROM docker.io/bitnami/etcd:3.5.6-debian-11-r10

USER root
COPY libetcd.sh /opt/bitnami/scripts/libetcd.sh
COPY run.sh entrypoint.sh /opt/bitnami/scripts/etcd/
RUN chmod +x \
    /opt/bitnami/scripts/etcd/run.sh \
    /opt/bitnami/scripts/etcd/entrypoint.sh \
    /opt/bitnami/scripts/libetcd.sh
USER 1001
