# k8s-crd-extractor

Runs [`crd-extractor.sh`](https://github.com/datreeio/CRDs-catalog/tree/main/Utilities) from datreeio/CRDs-catalog
to export all CRDs of a cluster as JSON schemas (used by `jobs/publish-k8s-schemas` → schemas.sstr.dev).

`VERSION` is a CRDs-catalog commit SHA (upstream has no releases), so only `rolling` is published — pin by digest.
Based on the [bjw-s-labs image](https://github.com/bjw-s-labs/container-images/tree/main/apps/k8s-crd-extractor).
