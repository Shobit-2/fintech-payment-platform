package com.fintech.paymentplatform.dto;

import com.fintech.paymentplatform.entity.TransactionStatus;
import com.fintech.paymentplatform.entity.TransactionType;

import java.math.BigDecimal;
import java.time.Instant;

public class TransactionResponse {

    private Long id;
    private Long senderWalletId;
    private Long receiverWalletId;
    private BigDecimal amount;
    private TransactionStatus status;
    private TransactionType type;
    private Instant createdAt;

    public TransactionResponse(Long id, Long senderWalletId, Long receiverWalletId,
                                BigDecimal amount, TransactionStatus status,
                                TransactionType type, Instant createdAt) {
        this.id = id;
        this.senderWalletId = senderWalletId;
        this.receiverWalletId = receiverWalletId;
        this.amount = amount;
        this.status = status;
        this.type = type;
        this.createdAt = createdAt;
    }

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

    public TransactionType getType() {
        return type;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
