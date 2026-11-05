# Agendamento Odontológico — API

API Spring Boot 4 / Java 21 publicada com Docker no Render, usando MySQL no Aiven
e CI/CD com GitHub Actions.

## Stack

- Java 21 + Spring Boot 4.1
- Spring Web MVC, Spring Data JPA, Spring Security (JWT)
- Flyway (migrations em `src/main/resources/db/migration`)
- MySQL (Aiven)
- Docker (multi-stage build)
- GitHub Actions (testes + build)
- Render (deploy)

## Variáveis de ambiente

A aplicação **não** guarda credenciais no código. Ela lê:

| Variável | Exemplo | Onde é usada |
|---|---|---|
| `DB_URL` | `jdbc:mysql://host:porta/defaultdb?sslMode=REQUIRED` | conexão JDBC |
| `DB_USERNAME` | `avnadmin` | usuário do banco |
| `DB_PASSWORD` | `********` | senha do banco |
| `JWT_SECRET` | chave aleatória (256 bits) | assinatura dos tokens JWT |
| `PORT` | injetada pelo Render | porta HTTP (padrão 8080) |

### Rodando localmente

Copie `.env.example` para `.env` e preencha os valores (o `.env` não vai para o Git).

Para carregar o `.env` na sessão do PowerShell:

```powershell
Get-Content .env | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    Set-Item -Path "Env:$($k.Trim())" -Value $v.Trim()
}
.\mvnw.cmd spring-boot:run
```

Ou via Maven Wrapper, definindo as variáveis manualmente:

```powershell
$env:DB_URL="jdbc:mysql://SEU_HOST:SUA_PORTA/defaultdb?sslMode=REQUIRED"
$env:DB_USERNAME="avnadmin"
$env:DB_PASSWORD="SUA_SENHA"
$env:JWT_SECRET="SUA_CHAVE"
.\mvnw.cmd spring-boot:run
```

Health check: <http://localhost:8080/actuator/health>

### Gerando uma chave JWT de 256 bits

```powershell
$bytes = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

## Testes e build

```powershell
.\mvnw.cmd clean verify
docker build -t agendamento-odontologico .
docker run -p 8080:8080 --env-file .env agendamento-odontologico
```

## CI/CD

Workflow: `.github/workflows/agendamento-odontologico-cicd.yml`

- `test-and-build`: roda em todo push na `main` (e manualmente), executa
  `./mvnw clean verify` com os secrets do banco e valida o `docker build`.
- `deploy`: só roda se a **variable** `DEPLOY_ENABLED` for `true`. Dispara o
  deploy hook do Render.

Secrets necessários (Settings → Secrets and variables → Actions):
`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `RENDER_DEPLOY_HOOK`.

## Deploy no Render

- Runtime: Docker
- Root Directory: vazio (o `pom.xml` e o `Dockerfile` estão na raiz)
- Dockerfile Path: `./Dockerfile`
- Health Check Path: `/actuator/health`
- Environment Variables: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`
  (não definir `PORT`; o Render injeta automaticamente)
