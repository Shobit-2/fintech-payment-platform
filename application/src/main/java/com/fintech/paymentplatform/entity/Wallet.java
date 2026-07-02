package com.fintech.paymentplatform.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Financial identity — holds the balance. Separated from User so that auth concerns
 * never mix with money-handling concerns.
 *
 * IMPORTANT: balance uses BigDecimal, never float/double. Floating point binary
 * representations cannot exactly represent most decimal fractions (e.g. 0.1),
 * which causes silent rounding errors — unacceptable for financial data.
 */
@Entity
@Table(name = "wallets")
public class Wallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // precision=19, scale=4 -> supports large balances with sub-cent accuracy,
    // a common convention in financial systems to avoid rounding during intermediate calculations.
    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(nullable = false, length = 3)
    private String currency = "USD";

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_user_id", nullable = false, unique = true)
    private User owner;

    @Column(nullable = false, updatable = false, name = "created_at")
    private Instant createdAt;

    // Optimistic locking: prevents two concurrent transfers from corrupting
    // the balance via a lost-update race condition. Hibernate checks this
    // version column on every UPDATE and throws if it has changed since read.
    @Version
    private Long version;

    protected Wallet() {
    }

    public Wallet(User owner) {
        this.owner = owner;
        this.balance = BigDecimal.ZERO;
    }

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    // --- Getters and setters ---

    public Long getId() {
        return id;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    public void setBalance(BigDecimal balance) {
        this.balance = balance;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public User getOwner() {
        return owner;
    }

    public void setOwner(User owner) {
        this.owner = owner;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Long getVersion() {
        return version;
    }
}
