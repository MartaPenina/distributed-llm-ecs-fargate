# Web Service (AnythingLLM) — no Dockerfile needed

Unmodified upstream image, pulled directly in the ECS Task Definition.

- Image: mintplexlabs/anythingllm:pg (pg = pgvector-enabled variant for our RDS)
- Container port: 3001 (internal)
- Env vars needed at Task Definition time:
  - DATABASE_URL = postgresql://llmadmin:<db_password>@<db_host>:5432/anythingllm_db
  - STORAGE_DIR = /app/server/storage
  - AUTH_TOKEN = <anythingllm_password from SSM>
  - JWT_SECRET = <anythingllm_jwt_secret from SSM>
- Needs persistent storage (EFS access point) for STORAGE_DIR — otherwise
  chat history/settings are lost on every task restart
- SSM secrets already exist under /distributed-llm-aws/dev/* — decide in
  requirement 10 whether to reuse that path or copy to new project namespace