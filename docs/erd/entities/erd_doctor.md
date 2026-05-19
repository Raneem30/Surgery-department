# Entity: Doctor

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eDoctor[DOCTOR]:::entity
    aPk([ssn PK]:::attr
    aName([name]:::attr
    aSex([sex]:::attr
    aBdate([birth_date]:::attr
    aMajor([major_area]:::attr
    aDegree([degree]:::attr
    aDeptFk([department_code FK]:::attr
    aJoin([join_date]:::attr

    eDoctor --- aPk & aName & aSex & aBdate & aMajor & aDegree & aDeptFk & aJoin
```
