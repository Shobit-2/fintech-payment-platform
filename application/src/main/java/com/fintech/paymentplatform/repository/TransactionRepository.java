package com.fintech.paymentplatform.repository;

import com.fintech.paymentplatform.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    List<Transaction> findBySenderWalletIdOrReceiverWalletIdOrderByCreatedAtDesc(
            Long senderWalletId, Long receiverWalletId);

    // Used by the fraud rule: "flag if more than N transfers in a short window"
    List<Transaction> findBySenderWalletIdAndCreatedAtAfter(Long senderWalletId, Instant since);
}
