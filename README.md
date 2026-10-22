# nuclei-scanner

Containerized [nuclei](https://github.com/projectdiscovery/nuclei) for
vulnerability scanning of web apps, hosts, and cloud/private-network
endpoints.

- Multi-stage build: nuclei is compiled from a pinned tag, then copied into a
  distroless `nonroot` image (no shell, no package manager).
- Runs as uid 65532, read-only root filesystem, all Linux capabilities dropped,
  `no-new-privileges`, CPU/memory/PID limits.
- Templates live in a named volume, updated by a separate maintenance service.
- Targets are mounted read-only; reports are written to `./reports`.

## Layout

```
Dockerfile            multi-stage build, pinned nuclei version
docker-compose.yml    nuclei-update (maintenance) and nuclei-scan services
.env.example          copy to .env
targets/example.txt   sample target list (real lists are gitignored)
reports/              JSONL findings (gitignored)
```

## Setup

```sh
cp .env.example .env
mkdir -p reports
# Linux only: the container writes as uid 65532
sudo chown 65532:65532 reports

docker compose build
docker compose --profile maintenance run --rm nuclei-update   # first template download
```

Refresh templates on a schedule (weekly is typical), for example from cron:

```cron
0 3 * * 1  cd /opt/nuclei-scanner && docker compose --profile maintenance run --rm nuclei-update
```

## Running scans

Create one target file per environment in `targets/` (for example
`targets/aws-prod-web.txt`, `targets/azure-internal.txt`). Then pick it at run
time:

```sh
TARGET_FILE=aws-prod-web.txt docker compose run --rm nuclei-scan
```

Use a different report name per run so results are not overwritten:

```sh
TARGET_FILE=azure-internal.txt REPORT_FILE=azure-$(date +%F).jsonl \
  docker compose run --rm nuclei-scan
```

Note: `docker compose run -e` does not change `${...}` values in the compose
file. Set variables in the shell or in `.env` / an env file instead.

Keep per-environment settings in `envs/<name>.env` (git-ignored) and pass them
with `--env-file`:

```sh
docker compose --env-file envs/aws-prod.env run --rm nuclei-scan
```

Findings are JSON Lines in `reports/`. Filter with `jq`, for example:

```sh
jq -r 'select(.info.severity=="critical" or .info.severity=="high")
  | [.info.severity, .info.name, .host] | @tsv' reports/results.jsonl
```

## Where to run it

nuclei must be able to reach the targets directly, so run a scanner inside each
network boundary rather than over the internet:

- **AWS:** a small EC2 instance (or ECS task) in each account/VPC. Reach
  private subnets over VPC peering or Transit Gateway. Use a security group that
  allows outbound only.
- **Azure:** a VM or container in each VNet/subscription, with access to
  private endpoints.
- **Private cloud / data center:** a Linux host on the internal network.

Send results from every scanner to one place (the `reports/` directory synced
to S3, Blob Storage, or your SIEM). Nothing in this repo sends data anywhere
on its own.

## Security notes

- `-exclude-tags dos` is always set. DoS templates can take a production
  service down.
- `-no-interactsh` is always set. Out-of-band callbacks go to a public service,
  which discloses target details. Trade-off: blind/OAST-only checks are skipped.
- Rate and concurrency are conservative by default (`RATE_LIMIT=50`,
  `CONCURRENCY=25`). Lower them for fragile production systems.
- No credentials are baked into the image. For authenticated scans, pass a
  token through an env-file or Docker secret and add a header with
  `-header "Authorization: ..."` (edit the command in `docker-compose.yml`). Do
  not commit credentials.
- The scanner has no cloud API access. Target discovery (for example from
  `aws ec2 describe-instances`) should use read-only roles and run outside this
  container.
- Scan only assets you own or are authorized to test. Check your cloud
  providers' penetration-testing and rules-of-engagement policies first.

## Upgrading nuclei

Change `NUCLEI_VERSION` in `.env`, then rebuild:

```sh
docker compose build --no-cache
```

Pinned tags are checked by `go install` against the Go checksum database. For
stronger supply-chain guarantees, pin the build image by digest in
`Dockerfile` (`golang:<version>-alpine@sha256:...`) and
`gcr.io/distroless/static-debian12:nonroot@sha256:...`.
