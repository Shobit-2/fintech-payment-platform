package com.fintech.paymentplatform;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Integration test - name ends in "IT" so Maven Failsafe (not Surefire) picks
 * it up, running during the 'verify' phase rather than 'test'. See pom.xml.
 * Verifies the entire Spring context (all beans, security config, JPA
 * mappings, Flyway migration) wires together correctly end-to-end.
 */
@SpringBootTest
class PaymentPlatformApplicationIT {

    @Test
    void contextLoads() {
        // If the Spring context fails to start (bad bean wiring, broken
        // migration, misconfigured security), this test fails - a cheap but
        // powerful smoke test for the whole application.
    }
}
