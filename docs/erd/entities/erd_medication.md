# Entity: Medication

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eMedication[MEDICATION]:::entity
    aPk([medication_id PK]:::attr
    aName([name UNIQUE]:::attr

    eMedication --- aPk & aName
```
