# Entity: Geo_Location

```mermaid
flowchart TD
    classDef entity fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef attr fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000

    eGeo[GEO_LOCATION]:::entity
    aPk([location_id PK]:::attr
    aLat([latitude]:::attr
    aLon([longitude]:::attr
    aAddr([address]:::attr
    aType([entity_type]:::attr
    aEid([entity_id]:::attr

    eGeo --- aPk & aLat & aLon & aAddr & aType & aEid
```
