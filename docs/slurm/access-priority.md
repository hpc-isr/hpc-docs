# Group-aware access and priority model

## Status

Working policy model based on stakeholder-provided requirements, recorded
2026-10-06. This document describes a generic model; it does not confirm that
any particular cluster has implemented or approved it. Resource administrators
must confirm local eligibility and scheduling settings before users rely on
them.

## Generic rules

- Determine access eligibility separately from scheduling priority.
- A shared research-computing pool may grant access to eligible researchers
  across its participating groups. Its administrators define role-based
  priorities for that pool.
- On a group-owned HPC resource, researchers affiliated with the owning group
  receive higher priority than eligible users from other groups.
- Cross-group access is conditional on the resource-owning group enabling it.
  When enabled, visiting groups receive lower priority than the owning group.
- A separate group server cluster may be restricted to that group's researchers.
  Do not infer access to it from eligibility for a shared HPC pool, and do not
  assume that it is managed by the scheduler.

## Unresolved policy details

- The exact ordering and scheduling implementation for researcher roles are
  not defined here.
- Resource administrators must confirm which groups participate in each shared
  pool and which group-owned resources permit cross-group access.
- Quotas, fair-share weights, limits, and any exceptions require separate
  decisions by the responsible administrators.
- Scheduler integration for a separate server cluster requires an explicit
  feasibility and ownership decision.

## Provenance and follow-up

The access distinctions above summarize stakeholder-provided requirements in
the HPC@ISR-Lisboa/LARSyS planning discussion on 2026-10-06. They are not
evidence of deployed configuration. Before publication as site policy, the
responsible shared-pool and group-resource administrators should confirm the
eligible groups, priority rules, and exceptions. Record any approved
site-specific configuration in its owning architecture or operations source.
