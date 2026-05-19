# Relational Mapping — ER to Schema

```mermaid
flowchart LR
    classDef erEntity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef relTable fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef junction fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:#000
    classDef mapping fill:#f3e5f5,stroke:#6a1b9a,stroke-width:1px,stroke-dasharray: 5 5,color:#000

    subgraph ER_Model["ER Model (Entities)"]
        direction TB
        ER_Patient(("Patient")):::erEntity
        ER_Hospital(("Hospital")):::erEntity
        ER_Department(("Department")):::erEntity
        ER_DeptLoc(("Department_Location")):::erEntity
        ER_Doctor(("Doctor")):::erEntity
        ER_Treats(("Treats")):::erEntity
        ER_Prescription(("Prescription")):::erEntity
        ER_Medication(("Medication")):::erEntity
        ER_PresMed(("Prescription_Medication")):::erEntity
        ER_Room(("Room")):::erEntity
        ER_Appointment(("Appointment")):::erEntity
        ER_Payment(("Payment")):::erEntity
        ER_User(("User")):::erEntity
        ER_Contact(("Contact_Inquiry")):::erEntity
        ER_Geo(("Geo_Location")):::erEntity
        ER_Scan(("Scan_Document")):::erEntity
    end

    subgraph Relational["Relational Schema (Tables)"]
        direction TB
        T_Patient["Patient"]:::relTable
        T_Hospital["Hospital"]:::relTable
        T_Department["Department"]:::relTable
        T_DeptLoc["Department_Location"]:::relTable
        T_Doctor["Doctor"]:::relTable
        T_Treats["Treats"]:::relTable
        T_Prescription["Prescription"]:::relTable
        T_Medication["Medication"]:::relTable
        T_PresMed["Prescription_Medication"]:::relTable
        T_Room["Room"]:::relTable
        T_Appointment["Appointment"]:::relTable
        T_Payment["Payment"]:::relTable
        T_User["User"]:::relTable
        T_Contact["Contact_Inquiry"]:::relTable
        T_Geo["Geo_Location"]:::relTable
        T_Scan["Scan_Document"]:::relTable
    end

    ER_Patient -->|→| T_Patient
    ER_Hospital -->|→| T_Hospital
    ER_Department -->|→| T_Department
    ER_DeptLoc -->|→| T_DeptLoc
    ER_Doctor -->|→| T_Doctor
    ER_Treats -->|→| T_Treats
    ER_Prescription -->|→| T_Prescription
    ER_Medication -->|→| T_Medication
    ER_PresMed -->|→| T_PresMed
    ER_Room -->|→| T_Room
    ER_Appointment -->|→| T_Appointment
    ER_Payment -->|→| T_Payment
    ER_User -->|→| T_User
    ER_Contact -->|→| T_Contact
    ER_Geo -->|→| T_Geo
    ER_Scan -->|→| T_Scan
```

## Mapping Rules Applied

| ER Construct | Mapping Rule | Resulting Table(s) |
|---|---|---|
| **Strong Entity** (Patient, Hospital, Doctor, etc.) | Direct mapping: each attribute → column, PK → PK | 1 table per entity |
| **Weak Entity** (Department_Location) | Include owner's PK as FK; composite PK = owner PK + partial key | 1 table |
| **M:N Relationship** (Treats, Prescription_Medication) | New table with both entity PKs as composite PK + FK | 1 junction table |
| **1:N Relationship** (Hospital → Dept, Dept → Doctor) | FK on N-side referencing PK of 1-side | FK column added to N-side table |
| **1:1 Relationship** (Appointment → Payment) | FK on either side with UNIQUE constraint | FK + UNIQUE on one table |
| **Self-referencing / Recursive** (Dept chairman → Doctor) | FK column referencing same table's PK | FK added to Department (chairman_ssn → Doctor.ssn) |

## Normalization

All tables are in **3NF**:

- **1NF**: Atomic columns, no repeating groups
- **2NF**: No partial dependencies — composite PKs are minimal and all non-key attributes depend on the full PK
- **3NF**: No transitive dependencies — all non-key attributes depend solely on the PK
