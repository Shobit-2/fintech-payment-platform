# ============================================================================
# STAGE 1: BUILD
# Uses a full JDK + Maven image to compile source and produce the JAR.
# This entire stage is discarded from the final image - only its output
# (the JAR file) gets copied forward.
# ============================================================================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

# Copy pom.xml first, separately from source code. Docker caches each
# instruction as a layer; as long as pom.xml doesn't change, this
# 'mvn dependency:go-offline' layer is reused on every subsequent build,
# so we don't re-download the internet's worth of dependencies every time
# we change a single Java file. This is one of the biggest CI speed wins
# available in Docker builds.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Now copy actual source and build. Only invalidates from this point
# forward when source changes - pom.xml layer above stays cached.
COPY src ./src
RUN mvn clean package -DskipTests -B

# ============================================================================
# STAGE 2: RUNTIME
# Minimal JRE (not JDK - we don't need the compiler at runtime) on a slim,
# security-patched base image. This is the image that actually ships to ECR
# and runs in EKS.
# ============================================================================
FROM eclipse-temurin:17-jre-jammy AS runtime

# Run as a non-root user. Running containers as root is a classic security
# anti-pattern - if the app is ever compromised via a code execution
# vulnerability, a non-root process limits what the attacker can do inside
# the container (can't install packages, can't modify system files, etc).
RUN groupadd --gid 1000 appgroup \
    && useradd --uid 1000 --gid appgroup --shell /bin/false --create-home appuser

WORKDIR /app

# Copy only the final JAR from the build stage - nothing else crosses over.
COPY --from=build /build/target/payment-platform.jar app.jar

# Ownership must be set explicitly - COPY defaults to root:root even though
# we'll run as appuser below.
RUN chown appuser:appgroup /app/app.jar

USER appuser

EXPOSE 8080

# Used by Docker/K8s to determine container health independent of the
# Kubernetes-level liveness/readiness probes we'll configure later - this
# is a lighter-weight, container-runtime-level check.
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# exec form (JSON array), not shell form - ensures the JVM receives signals
# (e.g. SIGTERM on `kubectl delete pod`) directly for graceful shutdown,
# instead of a shell process swallowing them.
ENTRYPOINT ["java", "-jar", "app.jar"]
