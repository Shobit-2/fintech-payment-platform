package com.fintech.paymentplatform.controller;

import com.fintech.paymentplatform.dto.WalletBalanceResponse;
import com.fintech.paymentplatform.entity.Wallet;
import com.fintech.paymentplatform.service.WalletService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping("/balance")
    public WalletBalanceResponse getBalance(Authentication authentication) {
        // authentication.getName() is populated by JwtAuthFilter from the
        // validated token's subject claim - see security/JwtAuthFilter.java
        String username = authentication.getName();
        Wallet wallet = walletService.getBalance(username);
        return new WalletBalanceResponse(wallet.getBalance(), wallet.getCurrency());
    }
}
