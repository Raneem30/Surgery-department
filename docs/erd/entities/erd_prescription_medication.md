# Entity: Prescription_Medication

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    ePresMed[PRESCRIPTION_MEDICATION]:::entity
    aRxFk([prescription_id PK FK]:::attr
    aMedFk([medication_id PK FK]:::attr
    aTimes([times_per_day]:::attr
    aDose([dose]:::attr

    ePresMed --- aRxFk & aMedFk & aTimes & aDose
```
