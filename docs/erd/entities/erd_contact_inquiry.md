# Entity: Contact_Inquiry

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eContact[CONTACT_INQUIRY]:::entity
    aPk([inquiry_id PK]:::attr
    aName([name]:::attr
    aEmail([email]:::attr
    aSubj([subject]:::attr
    aMsg([message]:::attr
    aTime([submitted_at]:::attr
    aRes([is_resolved]:::attr

    eContact --- aPk & aName & aEmail & aSubj & aMsg & aTime & aRes
```
