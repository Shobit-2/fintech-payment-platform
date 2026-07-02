package com.fintech.paymentplatform.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Immutable ledger record of a money movement. Transactions are INSERT-only —
 * they are never updated or deleted. This "append-only ledger" pattern is a
 * core financial-systems principle: the audit trail must be tamper-evident and
 * permanent. Status changes create business meaning, not row mutation in the
 * sense of altering historical facts (a FAILED transaction row still records
 * that the attempt happened).
 */
@Entity
@Table(name = "transactions")
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, name = "sender_wallet_id")
    private Long senderWalletId;

    @Column(nullable = false, name = "receiver_wallet_id")
    private Long receiverWalletId;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionType type;

    // 0-100 rule-based fraud risk score computed at transfer time.
    @Column(name = "fraud_score")
    private Integer fraudScore;

    @Column(nullable = false, updatable = false, name = "created_at")
    private Instant createdAt;

    protected Transaction() {
    }

    public Transaction(Long senderWalletId, Long receiverWalletId, BigDecimal amount,
                        TransactionType type) {
        this.senderWalletId = senderWalletId;
        this.receiverWalletId = receiverWalletId;
        this.amount = amount;
        this.type = type;
        this.status = TransactionStatus.PENDING;
    }

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    // --- Getters and setters (status/fraudScore are the only mutable fields,
    // since a transaction is finalized asynchronously as fraud checks run) ---

    public Long getId() {
        return id;
    }

    public Long getSenderWalletId() {
        return senderWalletId;
    }

    public Long getReceiverWalletId() {
        return receiverWalletId;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public TransactionStatus getStatus() {
        return status;
    }

    public void setStatus(TransactionStatus status) {
        this.status = status;
    }

    public TransactionType getType() {
        return type;
    }

    public Integer getFraudScore() {
        return fraudScore;
    }

    public void setFraudScore(Integer fraudScore) {
        this.fraudScore = fraudScore;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
