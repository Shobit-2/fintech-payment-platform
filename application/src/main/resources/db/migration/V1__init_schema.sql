-- V1__init_schema.sql
-- Initial schema for the Digital Payment Processing Platform.
-- Flyway applies this automatically on application startup against a fresh
-- database, which is exactly what happens after `terraform apply` recreates RDS.

CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE wallets (
    id            BIGSERIAL PRIMARY KEY,
    balance       NUMERIC(19,4) NOT NULL DEFAULT 0,
    currency      VARCHAR(3)    NOT NULL DEFAULT 'USD',
    owner_user_id BIGINT        NOT NULL UNIQUE REFERENCES users(id),
    created_at    TIMESTAMP     NOT NULL DEFAULT now(),
    version       BIGINT        NOT NULL DEFAULT 0
);

CREATE TABLE transactions (
    id                 BIGSERIAL PRIMARY KEY,
    sender_wallet_id   BIGINT        NOT NULL REFERENCES wallets(id),
    receiver_wallet_id BIGINT        NOT NULL REFERENCES wallets(id),
    amount             NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    status             VARCHAR(20)   NOT NULL,
    type               VARCHAR(20)   NOT NULL,
    fraud_score        INTEGER,
    created_at         TIMESTAMP     NOT NULL DEFAULT now()
);

-- Indexes for the query patterns our repositories use:
-- transaction history lookups filter/sort by wallet + time.
CREATE INDEX idx_transactions_sender_created ON transactions (sender_wallet_id, created_at DESC);
CREATE INDEX idx_transactions_receiver_created ON transactions (receiver_wallet_id, created_at DESC);
