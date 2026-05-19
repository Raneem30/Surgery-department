# Entity: Appointment

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eAppointment[APPOINTMENT]:::entity
    aPk([appointment_id PK]:::attr
    aPatFk([patient_number FK]:::attr
    aDocFk([doctor_ssn FK]:::attr
    aRoomFk([room_id FK]:::attr
    aDate([appointment_date]:::attr
    aStatus([status]:::attr

    eAppointment --- aPk & aPatFk & aDocFk & aRoomFk & aDate & aStatus
```
