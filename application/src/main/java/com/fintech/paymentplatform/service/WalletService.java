package com.fintech.paymentplatform.service;

import com.fintech.paymentplatform.entity.User;
import com.fintech.paymentplatform.entity.Wallet;
import com.fintech.paymentplatform.exception.ResourceNotFoundException;
import com.fintech.paymentplatform.repository.UserRepository;
import com.fintech.paymentplatform.repository.WalletRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class WalletService {

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;

    public WalletService(UserRepository userRepository, WalletRepository walletRepository) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
    }

    @Transactional(readOnly = true)
    public Wallet getBalance(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return walletRepository.findByOwner_Id(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));
    }
}
