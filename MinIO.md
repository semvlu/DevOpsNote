# MinIO
## Blob: Binary Larage Obj
- Independent of any hierarchy for acc. or avail.
- Rich metadata for context

## Bucket
- Collection of related obj, policies, config
- AWS S3: public DNS
- MinIO API: bucket creation as code
- App-Bucket intercation: GET, PUT

## Object Storage
- Support flexible bucket/ns, store data in any hierarchy, no matter flat or nested. 
- Obj: ID, data, full metadata
- Unlimited scaling thru storage pools
- REST, S3-Compatible API

## Erasure Coding
Redundancy & Avail, less overhead than RAID, replication.
Parity: param to shard obj into parities. 
- Lo: maximising avail storage
- Hi: maximising resiliency to node/drive loss.


```
<key>: <bucket>/(<prefix>)/<obj>
# prefix: sub-folder
# obj: filename

mc alias set local http://localhost:9000 minioadmin minioadmin
mc admin info local

# Make bucket
mc mb local/data 

# Write obj
mc cp path/to/file.csv local/data # direct @ bucket route
mc cp path/to/file1.csv local/data/<prefix>/file1.csv

# List
mc ls local/data
# Prefix shows 0B
mc ls local/data/<prefix>

# Output
mc cat <key>

# Delete
mc rm <key>

# Show Hierarchy
mc tree
```

## Versioning
Delete op producer "DeleteMarker" tombstone
- `mc cat` shows latest ver
- Able to retrieve non-cur ver
- `mc ls` "ignores" the marker.

```
mc version enable <bucket>

mc ls --versions <bucket>
mc [cat|rm] --version-id "<ver_id>" <key>

mc rm <key>
mc ls <bucket> # Does NOT show the obj which its latest ver is deleted.
mc ls --versions <bucket>
```

If versioning enabled, `rm`: soft delete, `rm --version-id`: hard delete.


## Setup
```
minio server <storage_resource_abs_path> --console-address :9090
```

## S3 Semantics
Rules of behaviours of S3 API
- Obj immutability: update = replace
- Read-after-write, list consistency
    ```
    PUT obj
    GET obj
    ```
    will see new obj immediately
- Key-based adr: bucket + key
- Metadata: content tpye, lifecycle, caching, tagging

[Install](https://docs.min.io/enterprise/aistor-object-store/installation/linux/install/deploy-aistor-on-ubuntu-server/)

[CLI](https://docs.min.io/enterprise/aistor-object-store/reference/cli/)

[MinIO Essentials for Admins](https://www.youtube.com/playlist?list=PLFOIsHSSYIK1gsQFfFnu9KE1qfhCTCMMM)
