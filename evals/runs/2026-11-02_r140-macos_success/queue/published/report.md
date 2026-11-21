### `published`: waiting (exit 0, 0.0 min of 5.0)

**For the owner:** answer `continue` once 1.4.0 is published and the tap's Casks/knaif.rb is pushed; the queue then checks the cask

To answer, comment (only the owner's accounts are read):

    ```knaif-decision
    step: published
    action: continue        # continue | rerun | stop
    accept:                 # optional: rules in accepted.yaml's form
      - {kind: regression, row: <row id>, models: [<model>], backends: [<backend>]}
    note: <optional>
    ```

```knaif-report
{
 "step": "published",
 "status": "waiting",
 "rc": 0,
 "elapsed_min": 0.0,
 "budget_min": 5.0,
 "cells": []
}
```