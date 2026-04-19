# OmniRoute bootstrap

Runtime environment for OmniRoute is sourced from the companion secrets repository and linked into this directory as `.env.local`.

Container state persists in the Docker named volume `rw-omniroute-data-live`.

The OmniRoute dashboard defaults to [http://localhost:20128/dashboard](http://localhost:20128/dashboard).

For non-invasive tests on machines that already run `rw-omniroute`, use
`scripts/test-omniroute-sandbox.sh` from the repository root. The sandbox
overrides `OMNIROUTE_CONTAINER_NAME`, `OMNIROUTE_VOLUME_NAME`, and
`OMNIROUTE_ENV_FILE` without changing the production defaults.
