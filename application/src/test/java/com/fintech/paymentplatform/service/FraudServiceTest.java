package com.fintech.paymentplatform.service;

import com.fintech.paymentplatform.entity.User;
import com.fintech.paymentplatform.entity.Wallet;
import com.fintech.paymentplatform.exception.FraudException;
import com.fintech.paymentplatform.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the fraud rule engine - mocked repository, no real database.
 * This is what Maven Surefire runs during the 'test' phase (see pom.xml).
 */
@ExtendWith(MockitoExtension.class)
class FraudServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private FraudService fraudService;

    private Wallet wallet;

    @BeforeEach
    void setUp() throws Exception {
        User owner = new User("alice", "alice@example.com", "hashed");
        wallet = new Wallet(owner);
        wallet.setBalance(new BigDecimal("500.00"));
        setId(wallet, 1L);
    }

    @Test
    void allowsTransferWithinBalanceAndLimit() {
        when(transactionRepository.findBySenderWalletIdAndCreatedAtAfter(anyLong(), any()))
                .thenReturn(Collections.emptyList());

        int score = fraudService.evaluate(wallet, new BigDecimal("100.00"));

        assertThat(score).isEqualTo(0);
    }

    @Test
    void blocksTransferExceedingBalance() {
        assertThatThrownBy(() -> fraudService.evaluate(wallet, new BigDecimal("600.00")))
                .isInstanceOf(FraudException.class)
                .hasMessageContaining("Insufficient balance");
    }

    @Test
    void blocksTransferExceedingMaxLimit() {
        wallet.setBalance(new BigDecimal("50000.00"));

        assertThatThrownBy(() -> fraudService.evaluate(wallet, new BigDecimal("10001.00")))
                .isInstanceOf(FraudException.class)
                .hasMessageContaining("maximum allowed limit");
    }

    @Test
    void raisesRiskScoreOnHighVelocity() {
        List<Object> fakeRecentTransfers = List.of(new Object(), new Object(), new Object(),
                new Object(), new Object());
        when(transactionRepository.findBySenderWalletIdAndCreatedAtAfter(anyLong(), any()))
                .thenReturn((List) fakeRecentTransfers);

        int score = fraudService.evaluate(wallet, new BigDecimal("10.00"));

        assertThat(score).isEqualTo(75);
    }

    private void setId(Wallet wallet, Long id) throws Exception {
        Field idField = Wallet.class.getDeclaredField("id");
        idField.setAccessible(true);
        idField.set(wallet, id);
    }
}
