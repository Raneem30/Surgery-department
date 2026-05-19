# Entity: Patient

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    ePatient[PATIENT]:::entity
    aPk([patient_number PK]:::attr
    aSsn([ssn UNIQUE]:::attr
    aName([name]:::attr
    aAddr([address]:::attr
    aPhone([phone]:::attr
    aBdate([birthdate]:::attr
    aSex([sex]:::attr
    aHist([medical_history]:::attr
    aBP([blood_pressure]:::attr
    aHR([heart_rate]:::attr
    aTemp([temperature]:::attr
    aAdmit([admission_date]:::attr

    ePatient --- aPk & aSsn & aName & aAddr & aPhone & aBdate & aSex & aHist & aBP & aHR & aTemp & aAdmit
```
