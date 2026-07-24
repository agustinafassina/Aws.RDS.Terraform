# .NET Consumption Guide — RDS via AWS Secrets Manager
Manual for consuming this Terraform-provisioned RDS instance from a **.NET / .NET 10** application when credentials live in **AWS Secrets Manager** (no password in config, code, or `appsettings.json`).

## Overview
```
.NET API  →  Secrets Manager (GetSecretValue)  →  JSON credentials  →  Npgsql / MySqlConnector  →  RDS (TLS)
```

Terraform stores a JSON secret like:

```json
{
  "username": "dbadmin",
  "password": "<generated>",
  "engine": "postgres",
  "host": "xxxx.region.rds.amazonaws.com",
  "port": 5432,
  "dbname": "appdb",
  "dbInstanceIdentifier": "my-app-dev-rds",
  "resourceId": "db-XXXXXXXX"
}
```

Your app only needs:

| Setting | Source |
|---------|--------|
| `AWS_REGION` | Environment / IAM role region |
| `DB_SECRET_ARN` | `terraform output -raw secrets_manager_secret_arn` |

## Prerequisites
1. RDS deployed with this template (`manage_master_user_password = false` default, or AWS-managed secret).
2. App runtime with an IAM role/user that can read the secret (and decrypt with the CMK if used).
3. Network path to RDS: same VPC (or peering/PrivateLink) and security group allowed via `allowed_security_group_ids`.
4. .NET 10 SDK.

### Get the secret ARN after deploy
```bash
terraform output -raw secrets_manager_secret_arn
```

### IAM policy (attach to the API role)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadDbSecret",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:eu-west-1:123456789012:secret:my-app-*-rds-credentials-*"
    },
    {
      "Sid": "DecryptWithCmk",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:eu-west-1:123456789012:key/your-cmk-id",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.eu-west-1.amazonaws.com"
        }
      }
    }
  ]
}
```

Replace ARNs with your outputs (`secrets_manager_secret_arn`, `kms_key_arn`).

> Prefer **instance/task/pod IAM roles** (EC2, ECS, EKS, Lambda). Avoid long-lived access keys in the app.

## NuGet packages
### PostgreSQL
```bash
dotnet add package AWSSDK.SecretsManager
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
# or without EF:
dotnet add package Npgsql
```

### MySQL / MariaDB
```bash
dotnet add package AWSSDK.SecretsManager
dotnet add package MySqlConnector
# or:
dotnet add package Pomelo.EntityFrameworkCore.MySql
```

## Configuration (no password in files)
`appsettings.json` — only non-secret settings:

```json
{
  "Aws": {
    "Region": "eu-west-1",
    "DbSecretArn": ""
  }
}
```

Prefer environment variables / secrets injection in the host:

```bash
AWS_REGION=eu-west-1
DB_SECRET_ARN=arn:aws:secretsmanager:eu-west-1:123456789012:secret:xxxx
```

`appsettings.Development.json` can override the ARN for local testing **only if** you use AWS SSO / profiles — still never put the DB password there.

## Sample: secret model + client
```csharp
// DbSecret.cs
namespace MyApp.Data;

public sealed class DbSecret
{
    public string Username { get; init; } = "";
    public string Password { get; init; } = "";
    public string Engine { get; init; } = "";
    public string Host { get; init; } = "";
    public int Port { get; init; }
    public string Dbname { get; init; } = "";
}
```

```csharp
// SecretsManagerDbSecretProvider.cs
using System.Text.Json;
using Amazon;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using Microsoft.Extensions.Caching.Memory;

namespace MyApp.Data;

public interface IDbSecretProvider
{
    Task<DbSecret> GetAsync(CancellationToken ct = default);
}

public sealed class SecretsManagerDbSecretProvider : IDbSecretProvider
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly IAmazonSecretsManager _secrets;
    private readonly IMemoryCache _cache;
    private readonly string _secretArn;
    private readonly TimeSpan _cacheTtl;

    public SecretsManagerDbSecretProvider(
        IAmazonSecretsManager secrets,
        IMemoryCache cache,
        IConfiguration config)
    {
        _secrets = secrets;
        _cache = cache;
        _secretArn = config["DB_SECRET_ARN"]
            ?? config["Aws:DbSecretArn"]
            ?? throw new InvalidOperationException("DB_SECRET_ARN is not configured.");
        _cacheTtl = TimeSpan.FromMinutes(
            int.TryParse(config["Aws:DbSecretCacheMinutes"], out var m) ? m : 10);
    }

    public async Task<DbSecret> GetAsync(CancellationToken ct = default)
    {
        const string cacheKey = "rds-db-secret";

        if (_cache.TryGetValue(cacheKey, out DbSecret? cached) && cached is not null)
            return cached;

        var response = await _secrets.GetSecretValueAsync(
            new GetSecretValueRequest { SecretId = _secretArn }, ct);

        var secret = JsonSerializer.Deserialize<DbSecret>(response.SecretString, JsonOptions)
            ?? throw new InvalidOperationException("Secret payload is empty or invalid.");

        _cache.Set(cacheKey, secret, _cacheTtl);
        return secret;
    }
}
```

## Sample: PostgreSQL with Npgsql + EF Core (.NET 10)
```csharp
// Program.cs
using Amazon.SecretsManager;
using Microsoft.EntityFrameworkCore;
using MyApp.Data;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddMemoryCache();
builder.Services.AddAWSService<IAmazonSecretsManager>();
builder.Services.AddSingleton<IDbSecretProvider, SecretsManagerDbSecretProvider>();

builder.Services.AddDbContext<AppDbContext>((sp, options) =>
{
    // Sync resolve at startup is OK for first connection string build;
    // for rotation-friendly setups, use NpgsqlDataSource (below).
    var provider = sp.GetRequiredService<IDbSecretProvider>();
    var secret = provider.GetAsync().GetAwaiter().GetResult();

    var csb = new NpgsqlConnectionStringBuilder
    {
        Host = secret.Host,
        Port = secret.Port,
        Username = secret.Username,
        Password = secret.Password,
        Database = secret.Dbname,
        SslMode = SslMode.Require,
        Pooling = true,
        MaxPoolSize = 50
    };

    options.UseNpgsql(csb.ConnectionString);
});

builder.Services.AddControllers();
var app = builder.Build();
app.MapControllers();
app.Run();
```

### Better: `NpgsqlDataSource` with lazy secret load
```csharp
builder.Services.AddSingleton(sp =>
{
    var provider = sp.GetRequiredService<IDbSecretProvider>();
    var secret = provider.GetAsync().GetAwaiter().GetResult();

    var csb = new NpgsqlConnectionStringBuilder
    {
        Host = secret.Host,
        Port = secret.Port,
        Username = secret.Username,
        Password = secret.Password,
        Database = secret.Dbname,
        SslMode = SslMode.Require
    };

    return new NpgsqlDataSourceBuilder(csb.ConnectionString).Build();
});

builder.Services.AddDbContext<AppDbContext>((sp, options) =>
{
    options.UseNpgsql(sp.GetRequiredService<NpgsqlDataSource>());
});
```

### Minimal API endpoint example

```csharp
app.MapGet("/health/db", async (AppDbContext db, CancellationToken ct) =>
{
    var ok = await db.Database.CanConnectAsync(ct);
    return ok ? Results.Ok(new { status = "ok" }) : Results.StatusCode(503);
});
```

## Sample: MySQL / MariaDB with MySqlConnector
```csharp
using MySqlConnector;

var secret = await secretProvider.GetAsync();

var csb = new MySqlConnectionStringBuilder
{
    Server = secret.Host,
    Port = (uint)secret.Port,
    UserID = secret.Username,
    Password = secret.Password,
    Database = secret.Dbname,
    SslMode = MySqlSslMode.Required,
    Pooling = true
};

await using var conn = new MySqlConnection(csb.ConnectionString);
await conn.OpenAsync();
```

## Local development
| Approach | Notes |
|----------|--------|
| **AWS SSO / profile** | `aws sso login`, then run the API with `DB_SECRET_ARN` set. SDK picks up the profile. |
| **VPN / SSM bastion** | Required if your laptop is outside the VPC (RDS is private). |
| **Dev override (discouraged)** | Only for throwaway labs; never commit passwords. Prefer reading the real secret. |

Example `launchSettings.json` env vars:

```json
{
  "profiles": {
    "MyApp": {
      "commandName": "Project",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "AWS_REGION": "eu-west-1",
        "AWS_PROFILE": "my-sso-profile",
        "DB_SECRET_ARN": "arn:aws:secretsmanager:eu-west-1:123456789012:secret:xxxx"
      }
    }
  }
}
```

## Networking checklist
1. API security group ID is listed in Terraform `allowed_security_group_ids` (or its CIDR in `allowed_cidr_blocks`).
2. API and RDS share a network path (same VPC / peered VPC).
3. TLS is enforced by the RDS parameter group (`rds.force_ssl` / `require_secure_transport`) — clients must use SSL.
4. DNS hostnames work inside the VPC (`enable_dns_hostnames` is enabled by this template).

## Optional: IAM database authentication (.NET)
If you enable IAM DB auth instead of (or in addition to) password auth:

1. Create a DB user granted `rds_iam` (PostgreSQL) / equivalent for MySQL.
2. Generate an auth token with `RDSAuthTokenGenerator` (AWSSDK.RDS).
3. Connect with that token as the password (short-lived ~15 minutes).

Password + Secrets Manager (this guide) is usually simpler for classic .NET APIs. Use IAM auth when you want keyless DB login tied to IAM roles.

## Operational tips
- **Cache** the secret (5–15 minutes). Do not call `GetSecretValue` on every HTTP request.
- On auth failures after rotation, **invalidate the cache** and fetch again.
- Prefer `manage_master_user_password = true` in Terraform if you want AWS-managed rotation; then read the RDS-managed secret ARN the same way.
- Never log `SecretString` or connection strings with passwords.
- Use connection pooling (`Pooling=true`) for REST APIs under load.

## Quick verification
```bash
# 1) Confirm secret exists
aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --query SecretString \
  --output text | jq 'del(.password) | . + {password:"***"}'

# 2) Run API
dotnet run

# 3) Hit a health endpoint that opens a DB connection
curl https://localhost:5001/health/db
```

## Related
- Main project docs: [../README.md](../README.md)
- Terraform output: `secrets_manager_secret_arn`
- Security group output: `security_group_id` (allow your API SG toward this)
