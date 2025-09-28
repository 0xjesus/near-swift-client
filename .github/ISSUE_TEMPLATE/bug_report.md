name: Bug report
description: Report a bug in NEAR Swift JSON-RPC client
labels: [bug]
body:
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: Also tell us what you expected to happen.
    validations:
      required: true
  - type: textarea
    id: repro
    attributes:
      label: Reproduction steps
  - type: input
    id: version
    attributes:
      label: Package version / commit
