package com.fintech.paymentplatform.dto;

import java.math.BigDecimal;

public class WalletBalanceResponse {

    private BigDecimal balance;
    private String currency;

    public WalletBalanceResponse(BigDecimal balance, String currency) {
        this.balance = balance;
        this.currency = currency;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    public String getCurrency() {
        return currency;
    }
}
