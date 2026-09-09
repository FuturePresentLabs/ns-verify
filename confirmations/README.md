# Publication gate records

Commit exactly one evidence record before publishing. Use one of these forms.

```yaml
gate: independent-confirmation
confirmed_by: Name or established handle
source_url: https://...
checked_utc: 2026-09-08T00:00:00Z
notes: What exact commit and checks they confirmed
```

Or, only after a genuine 72-hour public no-refutation window:

```yaml
gate: 72h-no-refutation
window_started_epoch: 0
checked_epoch: 259200
window_started_utc: 2026-09-08T00:00:00Z
checked_utc: 2026-09-11T00:00:00Z
public_evidence_url: https://...
notes: Where the logs were available and monitored
```

The epoch fields make the 72-hour gate mechanically checkable. Replace example values; do not treat this README as evidence.

