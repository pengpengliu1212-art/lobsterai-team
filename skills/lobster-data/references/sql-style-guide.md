# SQL Style Guide for lobster-data

> Per text-to-SQL best practices (Medium, PuppyGraph, ezinsights 2026).

## Query writing rules

### Read-only by default

- All queries default to `SELECT` only
- `INSERT` / `UPDATE` / `DELETE` require explicit human approval
- `DROP` / `TRUNCATE` / `ALTER TABLE` always require human approval (separate approval, not just "yes")

### Always include LIMIT or query_timeout

```sql
-- OK
SELECT * FROM users WHERE created_at > '2026-01-01' LIMIT 1000;

-- OK
SET statement_timeout = '30s';
SELECT * FROM users WHERE created_at > '2026-01-01';

-- NOT OK (no limit, no timeout)
SELECT * FROM users WHERE created_at > '2026-01-01';
```

### Use explicit column lists, never `SELECT *` in production

```sql
-- OK
SELECT id, name, email, created_at
FROM users
WHERE created_at > '2026-01-01'
LIMIT 1000;

-- NOT OK (in production queries)
SELECT * FROM users;
```

### Use CTEs for complex queries

```sql
-- OK
WITH active_users AS (
  SELECT id, name, email
  FROM users
  WHERE last_login_at > NOW() - INTERVAL '30 days'
),
recent_orders AS (
  SELECT user_id, COUNT(*) AS order_count
  FROM orders
  WHERE created_at > NOW() - INTERVAL '7 days'
  GROUP BY user_id
)
SELECT
  au.id,
  au.name,
  au.email,
  COALESCE(ro.order_count, 0) AS recent_orders
FROM active_users au
LEFT JOIN recent_orders ro ON au.id = ro.user_id
ORDER BY recent_orders DESC
LIMIT 100;
```

### Use sargable WHERE clauses

```sql
-- OK (sargable — can use index)
SELECT * FROM orders WHERE created_at >= '2026-01-01' AND created_at < '2026-02-01';

-- NOT OK (function on column — can't use index)
SELECT * FROM orders WHERE DATE(created_at) = '2026-01-15';
```

### Always qualify table names with schema

```sql
-- OK
SELECT id, name FROM analytics.users WHERE active = true;

-- NOT OK (ambiguous)
SELECT id, name FROM users WHERE active = true;
```

## Safety patterns

### PII protection by default

```sql
-- OK (only safe columns)
SELECT id, created_at, status
FROM orders
WHERE created_at > '2026-01-01'
LIMIT 1000;

-- NOT OK (PII without filter)
SELECT id, user_email, user_phone, shipping_address
FROM orders;
```

If PII is required → human approval + masking:

```sql
-- OK with approval
SELECT
  id,
  -- mask email
  CONCAT(LEFT(user_email, 3), '***@', SUBSTRING_INDEX(user_email, '@', -1)) AS masked_email,
  created_at
FROM orders
LIMIT 1000;
```

### Destructive operations require confirmation

```sql
-- These all require explicit human confirmation BEFORE running
DROP TABLE users;                    -- 永久删除整张表
TRUNCATE TABLE sessions;              -- 清空所有行
DELETE FROM users WHERE id = 123;     -- 删除特定行
UPDATE users SET active = false;      -- 批量更新
ALTER TABLE users DROP COLUMN email;  -- 删除列
```

### Read-only role assumption

When connecting to DB, lobster-data should use a read-only role by default:

```sql
-- OK
GRANT SELECT ON analytics.* TO 'lobster_data'@'%';

-- NOT OK (write access by default)
GRANT ALL PRIVILEGES ON analytics.* TO 'lobster_data'@'%';
```

## Validation checklist (before returning any SQL)

1. **Syntax validation** — `EXPLAIN` the query first
2. **Cost check** — estimated row count < LIMIT
3. **No destructive ops** without approval
4. **No PII** without approval
5. **Sargable WHERE** — no functions on indexed columns
6. **Explicit columns** — no `SELECT *` in production
7. **Schema-qualified tables** — `analytics.users`, not `users`
8. **Time-bounded** — `LIMIT` or `query_timeout`
9. **Result validation** — query returns expected shape (after running)

## Common anti-patterns

❌ `SELECT *` in production queries
❌ `DELETE` / `UPDATE` without `WHERE`
❌ Functions on indexed columns (`WHERE YEAR(date_col) = 2026`)
❌ Implicit type conversion (`WHERE varchar_col = 123`)
❌ `SELECT INTO` without explicit schema
❌ Joins on subqueries without alias
❌ Missing `LIMIT` on full table scans
❌ Hardcoded schema/table names without validation against DB metadata
