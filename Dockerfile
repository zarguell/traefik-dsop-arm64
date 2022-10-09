ARG BASE_REGISTRY=registry1.dso.mil
ARG BASE_IMAGE=ironbank/redhat/ubi/ubi8
ARG BASE_TAG=8.6

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

WORKDIR /opt/setup

## THIS IS Iron Bank version of Dockerfile to be submitted to Iron Bank repo for approval, do not spin this up locally

# ------------------------------------------------------------------------------------------------------------
# Per hardening manifest guidance: https://repo1.dso.mil/dsop/dccscr/-/tree/master/hardening%20manifest

# ----- OR ----- if installing without the hardening_manifest downloading things for us
COPY traefik.tar.gz /opt/traefik.tar.gz

USER root

RUN dnf update -y --nodocs && \
		dnf clean all && \
		rm -rf /var/cache/yum && \
		dnf remove -y vim-minimal

# unpack traefik
RUN tar xzvf /opt/traefik.tar.gz -C /usr/local/bin traefik && \
	rm -f /opt/traefik.tar.gz && \
	chmod 550 /usr/local/bin/traefik && \
	chown root /usr/local/bin/traefik && \
	chgrp root /usr/local/bin/traefik

COPY scripts/entrypoint.sh /entrypoint.sh
COPY config/traefik_example.toml /etc/traefik/traefik.toml

RUN chmod a+x /entrypoint.sh

USER 1001

HEALTHCHECK --start-period=15s --interval=15s --timeout=10s --retries=3 \
    CMD traefik healthcheck || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD traefik --ping
