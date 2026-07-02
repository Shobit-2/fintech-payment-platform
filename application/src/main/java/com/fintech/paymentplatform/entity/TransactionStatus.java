package com.fintech.paymentplatform.entity;

public enum TransactionStatus {
    PENDING,
    SUCCESS,
    FAILED,
    FLAGGED  // passed but marked for review by fraud rules
}
