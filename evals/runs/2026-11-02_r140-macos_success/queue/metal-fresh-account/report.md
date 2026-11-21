### `metal-fresh-account`: done (exit 0, 26.1 min of 60.0)

Done by hand after about 26 min; `/Users/Shared/knaif-metal-check/summary.txt` written.

summary.txt:
```text
Metal from a fresh standard account: 27.2, Apple M1 Pro
quarantine on bin/knaif: 0083;Safari
== cold
ggml_metal_device_init: GPU name:   MTL0 (Apple M1 Pro)
load_tensors: offloaded 37/37 layers to GPU
✓ wrote sample-rotated.pdf
real 14.50
exit 0
== warm
ggml_metal_device_init: GPU name:   MTL0 (Apple M1 Pro)
load_tensors: offloaded 37/37 layers to GPU
✓ wrote sample-rotated-1.pdf
real 3.95
exit 0
```
- **Metal: 37/37 layers, exit 0, both runs**

```knaif-report
{
 "step": "metal-fresh-account",
 "status": "done",
 "rc": 0,
 "elapsed_min": 26.1,
 "budget_min": 60.0,
 "cells": []
}
```