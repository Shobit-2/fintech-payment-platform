package com.fintech.paymentplatform.exception;

/**
 * Thrown when a request is well-formed but violates a business rule
 * (insufficient balance, duplicate username, transfer limit exceeded, etc).
 * Mapped to HTTP 400/409 by GlobalExceptionHandler depending on context.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
