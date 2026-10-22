# nuclei-vuln-mgmt

Docker-based vulnerability scanner built on nuclei v3.11.1. Image is built
from source and runs as a distroless, non-root container.

## Build and run

```sh
cp .env.example .env
docker compose build
docker compose --profile maintenance run --rm nuclei-update   # templates
TARGET_FILE=<file> docker compose run --rm nuclei-scan        # scan
```

- Target files live in `targets/` (git-ignored except `example.txt`).
- Reports are written to `reports/` as JSONL.
- `docker compose run -e` does not change `${...}` values in the compose file.
  Set variables in the shell, in `.env`, or with `--env-file`.
- The templates volume is named per compose project, so a fresh clone needs
  its own `nuclei-update` run before scanning.
- `nuclei-update` must not pass `-disable-update-check`, which also blocks
  template download.

## Security rules

- Never remove `-exclude-tags dos` or `-no-interactsh` without explicit approval.
- Never put credentials in the image, the compose file, or the repo.
- Scan only hosts you own or are authorized to test.
- Keep `.env`, `envs/`, `reports/`, and real `targets/*.txt` out of git.
- Keep the container hardened: read-only root filesystem, `cap_drop: ALL`,
  `no-new-privileges`, resource limits.
