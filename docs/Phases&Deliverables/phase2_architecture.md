# Phase 2: Spring Boot Application Architecture

## Tech Stack
- **Backend:** Spring Boot 3.x (Java 17+)
- **Database:** PostgreSQL (or MySQL)
- **Build:** Maven
- **ORM:** Spring Data JPA (optional — can use native SQL via JdbcTemplate)
- **Auth:** Spring Security + JWT
- **Frontend:** Thymeleaf (server-side) or React (separate)
- **API:** RESTful JSON

---

## Project Structure
```
surgery-department-app/
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/com/hospital/surgery/
│   │   │   ├── SurgeryApplication.java
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   └── WebConfig.java
│   │   │   ├── controller/
│   │   │   │   ├── HomeController.java
│   │   │   │   ├── AuthController.java
│   │   │   │   ├── PatientController.java
│   │   │   │   ├── DoctorController.java
│   │   │   │   ├── AppointmentController.java
│   │   │   │   ├── AdminController.java
│   │   │   │   └── ContactController.java
│   │   │   ├── model/
│   │   │   │   ├── Patient.java
│   │   │   │   ├── Doctor.java
│   │   │   │   ├── Appointment.java
│   │   │   │   ├── Prescription.java
│   │   │   │   ├── Room.java
│   │   │   │   ├── Payment.java
│   │   │   │   ├── User.java
│   │   │   │   └── ContactInquiry.java
│   │   │   ├── repository/
│   │   │   │   ├── PatientRepository.java
│   │   │   │   ├── DoctorRepository.java
│   │   │   │   └── AppointmentRepository.java
│   │   │   ├── service/
│   │   │   │   ├── PatientService.java
│   │   │   │   ├── DoctorService.java
│   │   │   │   ├── AppointmentService.java
│   │   │   │   └── DashboardService.java
│   │   │   └── dto/
│   │   │       ├── AppointmentDTO.java
│   │   │       └── DashboardStats.java
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── static/
│   │       └── templates/
│   └── test/
```

---

## Feature Mapping

| Feature | Controller | Service | Key Endpoints |
|---------|-----------|---------|--------------|
| Home page | HomeController | — | `GET /` |
| User auth | AuthController | — | `POST /login`, `POST /register` |
| Patient profiles | PatientController | PatientService | `GET /patients/{id}`, `PUT /patients/{id}` |
| Doctor profiles | DoctorController | DoctorService | `GET /doctors/{id}`, `GET /doctors/{id}/schedule` |
| Appointments | AppointmentController | AppointmentService | `POST /appointments`, `DELETE /appointments/{id}` |
| File uploads | PatientController | — | `POST /patients/{id}/scans` |
| Contact form | ContactController | — | `POST /contact` |
| Admin dashboard | AdminController | DashboardService | `GET /admin/dashboard` |
| Room management | AdminController | — | `POST /rooms/reserve` |
| Payments | AppointmentController | AppointmentService | `POST /appointments/{id}/pay`, `POST /appointments/{id}/refund` |

---

## Security Plan
- **Spring Security** with 4 roles: `ROLE_PATIENT`, `ROLE_DOCTOR`, `ROLE_NURSE`, `ROLE_ADMIN`
- **JWT** tokens for API auth
- Endpoint protection:
  - `/admin/**` → ADMIN only
  - `/patients/**` → PATIENT or ADMIN
  - `/doctors/**` → DOCTOR or ADMIN
  - `/appointments/**` → PATIENT, DOCTOR, or ADMIN
  - `/contact`, `/`, `/login`, `/register` → PUBLIC

---

## API Endpoints (REST)

### Public
| Method | Path | Description |
|--------|------|-------------|
| GET | / | Home page |
| POST | /api/auth/register | Register new user |
| POST | /api/auth/login | Login, returns JWT |
| POST | /api/contact | Submit contact form |

### Patient
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/patients/{id} | Get patient profile |
| PUT | /api/patients/{id} | Update patient info |
| GET | /api/patients/{id}/appointments | View my appointments |
| GET | /api/patients/{id}/prescriptions | View my prescriptions |
| POST | /api/patients/{id}/scans | Upload scan document |

### Doctor
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/doctors/{id} | Get doctor profile |
| GET | /api/doctors/{id}/patients | View my patients |
| GET | /api/doctors/{id}/appointments | View my schedule |
| POST | /api/doctors/{id}/prescriptions | Write prescription |
| PUT | /api/appointments/{id}/room | Reserve room for appointment |

### Appointment & Payment
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/appointments | Book appointment |
| DELETE | /api/appointments/{id} | Cancel appointment |
| POST | /api/appointments/{id}/pay | Pay for appointment |
| POST | /api/appointments/{id}/refund | Request refund |

### Admin
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/admin/dashboard | Dashboard stats |
| GET | /api/admin/reports/appointments | Appointment report |
| GET | /api/admin/reports/rooms | Room utilization report |
| GET | /api/admin/reports/revenue | Revenue report |

---

## Presentation Plan
1. **Demo walkthrough** (5 min): Show home page → Login as patient → Book appointment → Login as doctor → View schedule → Login as admin → Dashboard
2. **ERD explanation** (3 min): Key entities and relationships
3. **SQL highlights** (3 min): Show 2-3 complex queries (room utilization, doctor workload, revenue report)
4. **Architecture** (2 min): Spring Boot layers overview
