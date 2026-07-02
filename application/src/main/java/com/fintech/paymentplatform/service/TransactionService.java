package com.fintech.paymentplatform.service;

import com.fintech.paymentplatform.entity.*;
import com.fintech.paymentplatform.exception.BusinessException;
import com.fintech.paymentplatform.exception.ResourceNotFoundException;
import com.fintech.paymentplatform.repository.TransactionRepository;
import com.fintech.paymentplatform.repository.UserRepository;
import com.fintech.paymentplatform.repository.WalletRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class TransactionService {

    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final FraudService fraudService;

    public TransactionService(WalletRepository walletRepository, UserRepository userRepository,
                               TransactionRepository transactionRepository,
                               FraudService fraudService) {
        this.walletRepository = walletRepository;
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        this.fraudService = fraudService;
    }

    /**
     * Executes a wallet-to-wallet transfer atomically.
     *
     * Concurrency safety strategy (defense in depth):
     *  1. Rows are locked in a fixed order (lower wallet id first) via
     *     findByIdForUpdate (SELECT ... FOR UPDATE) to prevent deadlocks
     *     between two transfers that involve the same pair of wallets in
     *     opposite directions.
     *  2. @Transactional ensures debit + credit + ledger insert either all
     *     commit or all roll back together.
     *  3. Wallet.version (@Version / optimistic locking) is a second safety
     *     net in case row locking is ever bypassed by a different code path.
     */
    @Transactional
    public Transaction transfer(String senderUsername, String receiverUsername, BigDecimal amount) {
        if (senderUsername.equals(receiverUsername)) {
            throw new BusinessException("Cannot transfer to your own wallet");
        }

        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        User receiver = userRepository.findByUsername(receiverUsername)
                .orElseThrow(() -> new ResourceNotFoundException("Receiver: user not found"));

        Wallet senderWalletRef = walletRepository.findByOwner_Id(sender.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Sender wallet not found"));
        Wallet receiverWalletRef = walletRepository.findByOwner_Id(receiver.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet not found"));

        // Lock in a consistent order (by id) regardless of transfer direction,
        // so two opposite-direction transfers can never deadlock each other.
        Long firstLockId = Math.min(senderWalletRef.getId(), receiverWalletRef.getId());
        Long secondLockId = Math.max(senderWalletRef.getId(), receiverWalletRef.getId());

        Wallet first = walletRepository.findByIdForUpdate(firstLockId)
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));
        Wallet second = walletRepository.findByIdForUpdate(secondLockId)
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));

        Wallet senderWallet = senderWalletRef.getId().equals(first.getId()) ? first : second;
        Wallet receiverWallet = receiverWalletRef.getId().equals(first.getId()) ? first : second;

        // Fraud evaluation happens AFTER locking so the balance we check is
        // guaranteed current, not a stale read from before the lock was acquired.
        int fraudScore = fraudService.evaluate(senderWallet, amount);

        senderWallet.setBalance(senderWallet.getBalance().subtract(amount));
        receiverWallet.setBalance(receiverWallet.getBalance().add(amount));

        walletRepository.save(senderWallet);
        walletRepository.save(receiverWallet);

        Transaction transaction = new Transaction(
                senderWallet.getId(), receiverWallet.getId(), amount, TransactionType.TRANSFER);
        transaction.setFraudScore(fraudScore);
        transaction.setStatus(fraudScore >= 75 ? TransactionStatus.FLAGGED : TransactionStatus.SUCCESS);

        return transactionRepository.save(transaction);
    }

    @Transactional(readOnly = true)
    public List<Transaction> getHistory(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Wallet wallet = walletRepository.findByOwner_Id(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));

        return transactionRepository
                .findBySenderWalletIdOrReceiverWalletIdOrderByCreatedAtDesc(wallet.getId(), wallet.getId());
    }
}
