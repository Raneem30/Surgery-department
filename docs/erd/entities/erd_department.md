# Entity: Department

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eDepartment[DEPARTMENT]:::entity
    aPk([department_code PK]:::attr
    aName([name UNIQUE]:::attr
    aHospFk([hospital_id FK]:::attr
    aChairFk([chairman_ssn FK]:::attr
    aChairStart([chair_start_date]:::attr

    eDepartment --- aPk & aName & aHospFk & aChairFk & aChairStart
```
