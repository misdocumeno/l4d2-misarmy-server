# L4D2 Mis Army Server

## How to run

1. Configure `config/prod.yml`.

2. Create a `.env` file. Use `.env.example` as a template.

3. Generate the `docker-compose.yml` file.

```bash
gomplate \
    -f docker-compose.yml.tmpl \
    -c .="config/prod.yml" \
    > docker-compose.yml
```

4. Run `docker compose up -d`.
