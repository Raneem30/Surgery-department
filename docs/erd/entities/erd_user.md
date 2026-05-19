# Entity: User

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eUser[USER]:::entity
    aPk([user_id PK]:::attr
    aUname([username UNIQUE]:::attr
    aPwd([password_hash]:::attr
    aRole([role]:::attr
    aType([person_type]:::attr
    aPid([person_id]:::attr

    eUser --- aPk & aUname & aPwd & aRole & aType & aPid
```
