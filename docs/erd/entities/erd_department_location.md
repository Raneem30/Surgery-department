# Entity: Department_Location

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eDeptLoc[DEPARTMENT_LOCATION]:::entity
    aDeptFk([department_code PK FK]:::attr
    aLoc([location PK]:::attr

    eDeptLoc --- aDeptFk & aLoc
```
