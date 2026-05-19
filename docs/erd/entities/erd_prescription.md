# Entity: Prescription

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    ePrescription[PRESCRIPTION]:::entity
    aPk([prescription_id PK]:::attr
    aDocFk([doctor_ssn FK]:::attr
    aPatFk([patient_number FK]:::attr
    aRxDate([prescription_date]:::attr
    aStart([start_date]:::attr
    aEnd([end_date]:::attr

    ePrescription --- aPk & aDocFk & aPatFk & aRxDate & aStart & aEnd
```
