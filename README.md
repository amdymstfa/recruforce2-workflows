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

````

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
# Default credentials: admin@recruforce2.com / <secure-password>

# 5. Import workflows
./scripts/import-workflows.sh
````

---

## 🔧 Configuration

### Environment Variables

Edit `.env` file:

```bash
# N8N Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=<N8N_USER>
N8N_BASIC_AUTH_PASSWORD=<N8N_PASSWORD>

# Backend API
BACKEND_API_URL=<BACKEND_API_URL>

# AI Service
AI_SERVICE_URL=<AI_SERVICE_URL>

# Email (SMTP)
SMTP_HOST=<SMTP_HOST>
SMTP_PORT=<SMTP_PORT>
SMTP_USER=<SMTP_USERNAME>
SMTP_PASSWORD=<SMTP_PASSWORD>

# LinkedIn (Optional)
LINKEDIN_CLIENT_ID=<LINKEDIN_CLIENT_ID>
LINKEDIN_CLIENT_SECRET=<LINKEDIN_CLIENT_SECRET>
LINKEDIN_ACCESS_TOKEN=<LINKEDIN_ACCESS_TOKEN>

# Database
N8N_DATABASE_TYPE=postgresdb
N8N_DATABASE_POSTGRESDB_HOST=<POSTGRES_HOST>
N8N_DATABASE_POSTGRESDB_PORT=<POSTGRES_PORT>
N8N_DATABASE_POSTGRESDB_DATABASE=<POSTGRES_DB>
N8N_DATABASE_POSTGRESDB_USER=<POSTGRES_USER>
N8N_DATABASE_POSTGRESDB_PASSWORD=<POSTGRES_PASSWORD>
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

* Send positive email to candidate
* Notify recruiter with priority

5. If not qualified:

* Send polite rejection email

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

* Send reminder email to candidate
* Send reminder to interviewer
* Update reminder sent flag in backend

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

In Spring Boot `application.yml`:

```yaml
n8n:
  webhook:
    base-url: <N8N_BASE_URL>
    endpoints:
      cv-parsing: /webhook/cv-parsing
      application: /webhook/application
      job-posting: /webhook/job-posting
      notification: /webhook/notification
```

### Calling N8N from Backend

```java
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

Access N8N dashboard: [http://localhost:5678](http://localhost:5678)

* View workflow executions
* Check error logs
* Monitor performance
* Test workflows manually

Metrics:

* Workflow execution count
* Success/failure rate
* Average execution time
* Active workflows

---

## 🔒 Security Best Practices

* Use **strong passwords** for N8N UI
* Use **environment variables** for secrets
* Enable **HTTPS** in production
* Restrict webhook access by IP
* Rotate LinkedIn/SMTP credentials regularly

---

## 📦 Backup & Restore

### Backup Workflows

```bash
./scripts/export-workflows.sh
# Saved to ./backups/
```

### Restore Workflows

```bash
./scripts/import-workflows.sh
```

### Database Backup

```bash
docker-compose exec postgres pg_dump -U <POSTGRES_USER> <POSTGRES_DB> > backup.sql
```

---

## 🚀 Deployment

### Development

```bash
docker-compose up -d
```

### Production

```bash
docker-compose -f docker-compose.prod.yml up -d --restart=always
```

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

```
