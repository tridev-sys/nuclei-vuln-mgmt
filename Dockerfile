# syntax=docker/dockerfile:1

ARG GO_VERSION=1.26

FROM golang:${GO_VERSION}-alpine AS build
ARG NUCLEI_VERSION=v3.11.1
ENV CGO_ENABLED=0 GOFLAGS=-trimpath
# go install verifies the module against the Go checksum database.
RUN GOBIN=/out go install -ldflags="-s -w" \
      github.com/projectdiscovery/nuclei/v3/cmd/nuclei@${NUCLEI_VERSION} \
 && mkdir -p /out/nuclei-templates

# Distroless ships CA certificates and no shell, so there is nothing to
# exploit beyond the nuclei binary itself.
FROM gcr.io/distroless/static-debian12:nonroot
ARG NUCLEI_VERSION=v3.11.1
LABEL org.opencontainers.image.title="nuclei-scanner" \
      org.opencontainers.image.source="https://github.com/projectdiscovery/nuclei" \
      org.opencontainers.image.version="${NUCLEI_VERSION}"

COPY --from=build /out/nuclei /usr/local/bin/nuclei
# Owned by the runtime user so a fresh named volume inherits writable ownership.
COPY --from=build --chown=65532:65532 /out/nuclei-templates /opt/nuclei-templates

ENV HOME=/home/nonroot
USER 65532:65532
WORKDIR /home/nonroot

ENTRYPOINT ["/usr/local/bin/nuclei"]
CMD ["-h"]
