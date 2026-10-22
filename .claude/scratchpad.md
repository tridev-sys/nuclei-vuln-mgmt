# Scratchpad

## Current status

- Scanner pushed to `tridev-sys/nuclei-vuln-mgmt` on `main` (f0fedc3).
- Template-download bug fixed in d65c7f4: `nuclei-update` no longer passes
  `-disable-update-check`.
- Local test scan completed with templates loaded and found nothing (expected
  for a plain page).
- Dev portal scan (`portal.dev-frontend.grubgenie.ai`) completed in 4 minutes
  with 0 matches. Not verified that the scan reached the real app.

## Open questions

- Does the dev portal scan reach real application content? Zero matches may
  mean a clean target or a blocked/shallow scan.
- Do we want a known-vulnerable test target to prove detection works?

## Next steps

- Confirm the dev portal scan coverage (authenticated vs. anonymous).
- Decide on scheduling for template updates and recurring scans.

## Decisions log

- DoS templates excluded (`-exclude-tags dos`).
- Interactsh disabled (`-no-interactsh`) to avoid sending target data to a
  public OAST service.
- Distroless non-root base image.
- Go 1.26 required by nuclei v3.11.1.
