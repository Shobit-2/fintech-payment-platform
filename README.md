# Fintech Payment Platform

Digital Payment Processing Platform — a Java Spring Boot FinTech application built as the workload
for a production-grade AWS DevSecOps CI/CD pipeline.

This repository is organized as a monorepo:

```
fintech-payment-platform/
├── application/     # Spring Boot Java source code
├── kubernetes/      # K8s manifests (Deployment, Service, ConfigMap, Secret, PV/PVC)
├── terraform/       # AWS infrastructure as code (VPC, EKS, EC2, RDS, ECR, IAM)
├── jenkins/         # Jenkinsfile + Jenkins config-as-code
├── security/        # Security scan configs (Trivy, OWASP, ZAP policies)
├── monitoring/       # Prometheus/Grafana/Loki configs
└── README.md
```

Status: 🚧 Under active development (built incrementally as a guided DevSecOps course).

## Progress Log
- [x] Step 1: Architecture & tooling defined
- [x] Step 2: Domain design (User, Wallet, Transaction entities)
- [x] Step 3: Full Spring Boot application complete
  - [x] pom.xml (Maven build + JaCoCo + OWASP Dependency-Check + CycloneDX plugins wired)
  - [x] Entities: User, Wallet, Transaction (+ enums)
  - [x] Flyway migration (V1__init_schema.sql)
  - [x] Repositories (User, Wallet w/ pessimistic locking, Transaction)
  - [x] DTOs (request/response, validation annotated)
  - [x] Global exception handling
  - [x] Service layer: UserService, FraudService, TransactionService (atomic locked transfers), WalletService
  - [x] Security: JWT util, JWT filter, Spring Security config, BCrypt
  - [x] Controllers: Auth, Wallet, Transaction
  - [x] application.yml (env-var driven config, actuator/prometheus exposed)
  - [x] Unit tests (FraudService, UserService) + integration smoke test
- [x] Step 6: Jenkins installed on EC2 (Java 21, Docker, kubectl, AWS CLI, Maven), connected to GitHub
- [x] Step 7: Jenkinsfile - Stage 1 (Checkout) + Stage 2 (Build & Test + JaCoCo)
- [ ] Stage 3: SCA + SBOM
- [ ] Stage 4: SonarQube
- [ ] Stage 5: Docker build in pipeline
- [ ] Stage 6: Trivy scan
- [ ] Stage 7: Push to ECR
- [ ] Stage 8: EKS deployment
- [ ] Stage 9: ArgoCD GitOps
- [ ] Stage 10: DAST (OWASP ZAP)
- [ ] Stage 11: Smoke testing
- [ ] Stage 12: Canary/Blue-Green
- [ ] Stage 13: Monitoring (Prometheus/Grafana)
- [ ] Jenkins pipeline
- [x] Terraform: networking layer (VPC, subnets, NAT, security groups)
- [x] Terraform: Jenkins EC2 layer (IAM role, key pair, instance)
- [ ] Terraform: EKS cluster
- [ ] Terraform: ECR repository
- [ ] Terraform: RDS PostgreSQL
- [ ] Kubernetes manifests

## API Endpoints
| Method | Endpoint | Auth required |
|---|---|---|
| POST | /api/auth/register | No |
| POST | /api/auth/login | No |
| GET | /api/wallet/balance | Yes (Bearer JWT) |
| POST | /api/transactions/transfer | Yes (Bearer JWT) |
| GET | /api/transactions/history | Yes (Bearer JWT) |
| GET | /actuator/health | No |
| GET | /actuator/prometheus | No |

## Running Locally (once you have Postgres + Maven + JDK 17)
```bash
export DB_HOST=localhost DB_PORT=5432 DB_NAME=paymentplatform DB_USERNAME=postgres DB_PASSWORD=postgres
export JWT_SECRET=some-random-secret-at-least-32-characters-long
cd application
mvn clean package
java -jar target/payment-platform.jar
```

Note: this project's build was authored/reviewed without direct Maven Central
access in the authoring environment; first full `mvn clean package` should be
run either locally or in Jenkins (Stage 2) to confirm a clean compile.
