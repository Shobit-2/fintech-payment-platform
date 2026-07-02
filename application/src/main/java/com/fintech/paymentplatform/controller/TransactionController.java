package com.fintech.paymentplatform.controller;

import com.fintech.paymentplatform.dto.TransactionResponse;
import com.fintech.paymentplatform.dto.TransferRequest;
import com.fintech.paymentplatform.entity.Transaction;
import com.fintech.paymentplatform.service.TransactionService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @PostMapping("/transfer")
    public ResponseEntity<TransactionResponse> transfer(@Valid @RequestBody TransferRequest request,
                                                          Authentication authentication) {
        String senderUsername = authentication.getName();
        Transaction tx = transactionService.transfer(
                senderUsername, request.getReceiverUsername(), request.getAmount());
        return ResponseEntity.ok(toResponse(tx));
    }

    @GetMapping("/history")
    public List<TransactionResponse> history(Authentication authentication) {
        String username = authentication.getName();
        return transactionService.getHistory(username).stream()
                .map(this::toResponse)
                .toList();
    }

    private TransactionResponse toResponse(Transaction tx) {
        return new TransactionResponse(
                tx.getId(), tx.getSenderWalletId(), tx.getReceiverWalletId(),
                tx.getAmount(), tx.getStatus(), tx.getType(), tx.getCreatedAt());
    }
}
