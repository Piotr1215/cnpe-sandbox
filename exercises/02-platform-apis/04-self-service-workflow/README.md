# Implement Self-Service Provisioning Workflow

**Time:** 7 minutes
**Skills tested:** Self-Service APIs, Crossplane, Platform Automation

## Context

The platform team wants to enable self-service database provisioning. Developers should be able to request a database by creating a simple DatabaseRequest CR, and the platform should automatically provision it.

## Task

Create a self-service workflow in `cnpe-selfservice-test` namespace:

1. Create a **Crossplane Composition** that defines how to provision resources
2. Create a **CompositeResourceDefinition (XRD)** for the DatabaseRequest API
3. Create a test **DatabaseRequest** to verify the workflow

## Requirements

**XRD** (`xdatabaserequests.platform.cnpe.io`):
- Group: platform.cnpe.io
- Kind: XDatabaseRequest
- Claim kind: DatabaseRequest
- Properties: size (small/medium/large), engine (postgres/mysql)

**Composition** (`database-composition`):
- Composites: XDatabaseRequest
- Creates: ConfigMap with database connection info

## Verification

The exercise validates:
1. XRD exists and is established
2. Composition references correct composite type
3. DatabaseRequest claim can be created

## Allowed Documentation

- [Crossplane Compositions](https://docs.crossplane.io/latest/concepts/compositions/)
- [Composite Resource Definitions](https://docs.crossplane.io/latest/concepts/composite-resource-definitions-xrds/)
