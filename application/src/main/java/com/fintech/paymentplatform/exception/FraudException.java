package com.fintech.paymentplatform.exception;

/**
 * Thrown when the fraud engine hard-blocks a transaction (as opposed to merely
 * flagging it for review). Kept distinct from BusinessException so it can be
 * logged, alerted on, and monitored separately in Prometheus/Grafana later.
 */
public class FraudException extends RuntimeException {

    public FraudException(String message) {
        super(message);
    }
}
