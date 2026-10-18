# DYNAMODB-RDS

DynamoDB is managed NoSQL storage: tables contain items with attributes.
A partition key controls placement and an optional sort key orders items sharing
that partition key. Design keys from access patterns to avoid hot partitions.
Use cases include sessions and predictable key-based lookups.

RDS manages relational database instances with SQL engines such as PostgreSQL,
MySQL, MariaDB, Oracle and SQL Server, depending on region/offering. Use private
networking, encryption, controlled credentials, backups and maintenance. Multi-AZ
supports availability/failover; read replicas serve read scaling and may lag.
Backups enable recovery but the restore process must be tested. RDS fits
transactional applications with relational data.

Reference: https://docs.aws.amazon.com/
