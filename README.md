# RecruForce2 Workflows - N8N Orchestration 🔄

Automation workflows for RecruForce2 recruitment platform using N8N.

## 🎯 Overview

This repository contains N8N workflows that orchestrate the entire RecruForce2 ecosystem:

- **CV Processing**: Automatic parsing when CVs are uploaded
- **Application Workflow**: Trigger matching and notifications
- **Email Automation**: Send confirmations, reminders, and alerts
- **LinkedIn Integration**: Auto-post job offers to LinkedIn
- **Interview Management**: Schedule and send reminders
- **Analytics & Reporting**: Daily/weekly reports to recruiters

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    RECRUFORCE2                          │
│              N8N Workflow Orchestration                 │
└─────────────────────────────────────────────────────────┘

Backend (Spring Boot)          N8N Workflows          AI Service (Python)
Port: 8080                     Port: 5678             Port: 8000
      │                             │                       │
      │ Webhook Trigger             │                       │
      ├────────────────────────────►│                       │
      │                             │                       │
      │                             │ HTTP Request          │
      │                             ├──────────────────────►│
      │                             │                       │
      │                             │◄──────────────────────┤
      │                             │ Parse Response        │
      │                             │                       │
      │◄────────────────────────────┤                       │
      │ Update Database             │                       │
      │                             │                       │
      │                             │ Send Email            │
      │                             ├──────────► SMTP       │
      │                             │                       │
      │                             │ Post to LinkedIn      │
      │                             ├──────────► LinkedIn API
```

---

## 📦 Quick Start

### Prerequisites

- Docker & Docker Compose
- Backend Spring Boot running (port 8080)
- AI Service running (port 8000)
- SMTP credentials for emails
- LinkedIn API credentials (optional)

### Installation

```bash
# 1. Clone the repository
git clone <repo-url>
cd recruforce2-workflows

# 2. Copy environment file
cp .env.example .env
# Edit .env with your credentials

# 3. Start N8N
docker-compose up -d

# 4. Access N8N UI
open http://localhost:5678
# Default credentials: admin@recruforce2.com / recruforce2

# 5. Import workflows
./scripts/import-workflows.sh
```

---

## 🔧 Configuration

### Environment Variables

Edit `.env` file:

```bash
# N8N Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin@recruforce2.com
N8N_BASIC_AUTH_PASSWORD=recruforce2

# Backend API
BACKEND_API_URL=http://host.docker.internal:8080

# AI Service
AI_SERVICE_URL=http://host.docker.internal:8000

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# LinkedIn (Optional)
LINKEDIN_CLIENT_ID=your-client-id
LINKEDIN_CLIENT_SECRET=your-client-secret
LINKEDIN_ACCESS_TOKEN=your-access-token

# Database
N8N_DATABASE_TYPE=postgresdb
N8N_DATABASE_POSTGRESDB_HOST=postgres
N8N_DATABASE_POSTGRESDB_PORT=5432
N8N_DATABASE_POSTGRESDB_DATABASE=n8n
N8N_DATABASE_POSTGRESDB_USER=n8n
N8N_DATABASE_POSTGRESDB_PASSWORD=n8n_password
```

---

## 📊 Workflows

### 1. CV Parsing Workflow

**Trigger**: Backend sends webhook when CV is uploaded

**Flow**:
1. Receive webhook from backend with `candidateId` and `fileUrl`
2. Call AI Service `/api/parse-cv`
3. Receive parsed CV data
4. Update backend via `/api/candidates/{id}`
5. Send confirmation email to candidate
6. Notify recruiter

**File**: `workflows/cv-parsing-workflow.json`

---

### 2. Application Processing Workflow

**Trigger**: Backend sends webhook when application is submitted

**Flow**:
1. Receive application data (candidateId, jobOfferId)
2. Call AI Service `/api/match-score`
3. Update application with matching score
4. If qualified (score >= 60):
  - Send positive email to candidate
  - Notify recruiter with priority
5. If not qualified:
  - Send polite rejection email
6. Log to analytics

**File**: `workflows/application-processing-workflow.json`

---

### 3. LinkedIn Job Posting Workflow

**Trigger**: Backend webhook when job offer is published

**Flow**:
1. Receive job offer data
2. Format for LinkedIn API
3. Post to LinkedIn Company Page
4. Get LinkedIn Job ID
5. Update backend with LinkedIn Job ID
6. Send confirmation to recruiter

**File**: `workflows/linkedin-posting-workflow.json`

---

### 4. Interview Reminders Workflow

**Trigger**: Scheduled (Daily at 9:00 AM)

**Flow**:
1. Fetch interviews for next 24h from backend
2. For each interview:
  - Send reminder email to candidate
  - Send reminder to interviewer
  - Update reminder sent flag in backend

**File**: `workflows/interview-reminders-workflow.json`

---

### 5. Email Notifications Workflow

**Trigger**: Backend webhook for various events

**Flow**:
1. Receive notification event
2. Load email template based on event type
3. Populate template with data
4. Send email via SMTP
5. Log delivery status

**File**: `workflows/email-notifications-workflow.json`

---

## 🔗 Backend Integration

### Webhook Configuration

In your Spring Boot `application.yml`:

```yaml
n8n:
  webhook:
    base-url: http://localhost:5678
    endpoints:
      cv-parsing: /webhook/cv-parsing
      application: /webhook/application
      job-posting: /webhook/job-posting
      notification: /webhook/notification
```

### Calling N8N from Backend

```java
// Example: Trigger CV parsing workflow
@Service
public class N8NService {
    
    @Value("${n8n.webhook.base-url}")
    private String n8nBaseUrl;
    
    public void triggerCVParsing(Long candidateId, String fileUrl) {
        WebClient.create()
            .post()
            .uri(n8nBaseUrl + "/webhook/cv-parsing")
            .bodyValue(Map.of(
                "candidateId", candidateId,
                "fileUrl", fileUrl
            ))
            .retrieve()
            .bodyToMono(Void.class)
            .subscribe();
    }
}
```

---

## 📈 Monitoring

### N8N Dashboard

Access: http://localhost:5678

- View workflow executions
- Check error logs
- Monitor performance
- Test workflows manually

### Metrics

N8N provides metrics on:
- Workflow execution count
- Success/failure rate
- Average execution time
- Active workflows

---

## 🐛 Troubleshooting

### Workflow Not Triggering

```bash
# Check N8N logs
docker-compose logs -f n8n

# Test webhook manually
curl -X POST http://localhost:5678/webhook/cv-parsing \
  -H "Content-Type: application/json" \
  -d '{"candidateId": 1, "fileUrl": "http://example.com/cv.pdf"}'
```

### Email Not Sending

```bash
# Verify SMTP credentials in .env
# Test SMTP connection
docker-compose exec n8n n8n test-smtp
```

### Backend Not Reachable

```bash
# From N8N container, check connectivity
docker-compose exec n8n ping host.docker.internal
docker-compose exec n8n curl http://host.docker.internal:8080/health
```

---

## 🔒 Security

### Best Practices

- ✅ Use strong passwords for N8N UI
- ✅ Use environment variables for secrets
- ✅ Enable HTTPS in production
- ✅ Restrict webhook access by IP
- ✅ Rotate LinkedIn/SMTP credentials regularly

### Production Configuration

```yaml
# docker-compose.prod.yml
services:
  n8n:
    environment:
      - N8N_PROTOCOL=https
      - N8N_HOST=workflows.recruforce2.com
      - N8N_PORT=443
      - WEBHOOK_TUNNEL_URL=https://workflows.recruforce2.com
```

---

## 📦 Backup & Restore

### Backup Workflows

```bash
# Export all workflows
./scripts/export-workflows.sh

# Workflows saved to: ./backups/workflows-2026-02-20.json
```

### Restore Workflows

```bash
# Import workflows from backup
./scripts/import-workflows.sh ./backups/workflows-2026-02-20.json
```

### Database Backup

```bash
# Backup N8N database
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql
```

---

## 🚀 Deployment

### Development

```bash
docker-compose up -d
```

### Production

```bash
# Use production compose file
docker-compose -f docker-compose.prod.yml up -d

# Enable auto-restart
docker-compose -f docker-compose.prod.yml up -d --restart=always
```

### Scaling

N8N is stateful, so horizontal scaling requires:
- Shared database (PostgreSQL)
- Load balancer for webhooks
- Queue system for workflow execution

---

## 📚 Documentation

- [N8N Official Docs](https://docs.n8n.io/)
- [Workflow Examples](./docs/WORKFLOWS.md)
- [Integration Guide](./docs/INTEGRATION.md)
- [Setup Guide](./docs/SETUP.md)

---

## 🤝 Contributing

1. Create a new workflow in N8N UI
2. Export workflow as JSON
3. Place in `workflows/` directory
4. Update this README
5. Submit PR

---

## 📄 License

Proprietary - RecruForce2 © 2024

---

## 📞 Support

- **N8N UI**: http://localhost:5678
- **Logs**: `docker-compose logs -f n8n`
- **Health**: http://localhost:5678/healthz

---

