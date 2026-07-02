package com.fintech.paymentplatform.repository;

import com.fintech.paymentplatform.entity.Wallet;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface WalletRepository extends JpaRepository<Wallet, Long> {

    Optional<Wallet> findByOwner_Id(Long userId);

    /**
     * Pessimistic write lock: used inside the transfer service to lock both
     * sender and receiver wallet rows for the duration of the transaction,
     * preventing a second concurrent transfer from reading a stale balance.
     * Combined with @Version (optimistic locking) on the entity, this gives
     * defense in depth against race conditions on money movement.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT w FROM Wallet w WHERE w.id = :id")
    Optional<Wallet> findByIdForUpdate(@Param("id") Long id);
}
