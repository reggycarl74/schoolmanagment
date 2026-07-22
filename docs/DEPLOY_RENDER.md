# Deploy SchoolOS for review

This repository includes a Render Blueprint (`render.yaml`) for a free Docker web service and expects a MySQL-compatible TiDB Cloud Starter database.

In Render, create a Blueprint from this repository and provide the requested secret environment variables. Get `DB_HOST`, `DB_PORT`, `DB_NAME`, and `DB_USERNAME` from TiDB Cloud's **Connect** screen. Enter the database password as `DB_PASSWORD`, the local `config/master.key` value as `RAILS_MASTER_KEY`, and choose a strong `ADMIN_PASSWORD`. Set `APP_HOST` to the generated Render hostname without `https://` after the service is created.

The free Render filesystem is ephemeral. Uploaded logos, student documents, and lesson-plan files can disappear after a restart or redeploy. Use an S3-compatible object-storage service before production use.
