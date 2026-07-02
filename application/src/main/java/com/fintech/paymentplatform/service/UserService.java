package com.fintech.paymentplatform.service;

import com.fintech.paymentplatform.dto.RegisterRequest;
import com.fintech.paymentplatform.entity.User;
import com.fintech.paymentplatform.entity.Wallet;
import com.fintech.paymentplatform.exception.BusinessException;
import com.fintech.paymentplatform.repository.UserRepository;
import com.fintech.paymentplatform.repository.WalletRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, WalletRepository walletRepository,
                        PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Registers a new user AND creates their wallet in the same transaction.
     * If wallet creation failed silently, we'd have a user who can never
     * transact — @Transactional guarantees both succeed or neither does.
     */
    @Transactional
    public User register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BusinessException("Username already taken");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException("Email already registered");
        }

        String hashedPassword = passwordEncoder.encode(request.getPassword());
        User user = new User(request.getUsername(), request.getEmail(), hashedPassword);
        user = userRepository.save(user);

        Wallet wallet = new Wallet(user);
        walletRepository.save(wallet);

        return user;
    }
}
