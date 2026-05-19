# Entity: Scan_Document

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eScan[SCAN_DOCUMENT]:::entity
    aPk([scan_id PK]:::attr
    aPatFk([patient_number FK]:::attr
    aDocFk([doctor_ssn FK]:::attr
    aFile([file_path]:::attr
    aTime([upload_date]:::attr
    aDesc([description]:::attr

    eScan --- aPk & aPatFk & aDocFk & aFile & aTime & aDesc
```
