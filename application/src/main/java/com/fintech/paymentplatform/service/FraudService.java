package com.fintech.paymentplatform.service;

import com.fintech.paymentplatform.entity.Wallet;
import com.fintech.paymentplatform.exception.FraudException;
import com.fintech.paymentplatform.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Rule-based fraud engine. Real production fraud systems use ML models trained
 * on historical data; we use explainable, testable rules instead — this keeps
 * the logic transparent for a demo/learning project and gives us meaningful
 * behavior to unit test with JUnit/Mockito.
 *
 * Design: hard limit violations throw FraudException (block the transaction).
 * Soft signals (velocity checks) return a numeric risk score to be recorded,
 * not necessarily to block.
 */
@Service
public class FraudService {

    // Per-transaction hard limit. In a real system this would be configurable
    // per user tier (KYC level) rather than a single global constant.
    private static final BigDecimal MAX_TRANSACTION_AMOUNT = new BigDecimal("10000.00");

    // Velocity check window and threshold: more than 5 transfers from the same
    // wallet within 60 seconds is treated as suspicious (e.g. a compromised
    // account or a bot) and raises the fraud score without necessarily blocking.
    private static final int VELOCITY_WINDOW_SECONDS = 60;
    private static final int VELOCITY_THRESHOLD = 5;

    private final TransactionRepository transactionRepository;

    public FraudService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    /**
     * Runs all fraud checks for a proposed transfer.
     *
     * @return a 0-100 risk score to be stored on the transaction record.
     * @throws FraudException if a hard rule is violated (transaction must be blocked).
     */
    public int evaluate(Wallet sender, BigDecimal amount) {
        // Hard rule 1: cannot transfer more than you have.
        if (sender.getBalance().compareTo(amount) < 0) {
            throw new FraudException("Insufficient balance for this transfer");
        }

        // Hard rule 2: per-transaction ceiling.
        if (amount.compareTo(MAX_TRANSACTION_AMOUNT) > 0) {
            throw new FraudException(
                    "Transfer amount exceeds maximum allowed limit of " + MAX_TRANSACTION_AMOUNT);
        }

        // Soft rule: velocity check. Does not block, but raises the score,
        // which is recorded on the transaction for later review/monitoring.
        Instant windowStart = Instant.now().minus(VELOCITY_WINDOW_SECONDS, ChronoUnit.SECONDS);
        List<?> recentTransfers = transactionRepository
                .findBySenderWalletIdAndCreatedAtAfter(sender.getId(), windowStart);

        int riskScore = 0;
        if (recentTransfers.size() >= VELOCITY_THRESHOLD) {
            riskScore = 75;
        } else if (recentTransfers.size() >= VELOCITY_THRESHOLD / 2) {
            riskScore = 40;
        }

        return riskScore;
    }
}
