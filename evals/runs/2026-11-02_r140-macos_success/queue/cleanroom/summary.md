- host signatures: the .pkg notarized and accepted; every Mach-O in the .zip verifies

check_macho_deps --min-os 12.0 (information: TODO.md, the PDFium library declares 13):
```text
FAIL: 1 dependency/portability issue(s)

  - libpdfium.dylib: deployment floor is 13.0.0, expected 12.0.0 — MACOSX_DEPLOYMENT_TARGET was not honoured for this binary (it is not a rerun-if-env-changed input, so a stale cached build silently keeps the old floor — see D9)

An unresolved @rpath dependency resolves on THIS machine only because the file happens
to exist here (a build box, a Mac with Homebrew, ...). Stage it beside the binary, or
remove the dependency (see D3 for the OpenMP case).
```
- run1-zip: **CLEAN ROOM PASS (8 checks)**
- PDFium on macOS 12 (information): exit 0

PDFium on macOS 12:
```text
pdfium/knaif-1.4.0-macos-arm64/bin/libpdfium.dylib
xcode-select: error: no developer tools were found at '/Applications/Xcode.app', and no install could be requested (perhaps no UI is present), please install manually from 'developer.apple.com'.
⚠  No GPU backend is active — running on CPU. Inference will be slow (the first request can take a minute or more).
compress (rasterize — removes selectable text)
⚠ sample-compressed.pdf: couldn't make it smaller — kept it as it was
  not smaller (2.2 KB → 114.5 KB)
exit 0
-rw-r--r--  1 admin  staff  2221 20 Nov 03:39 sample-compressed.pdf
-rw-r--r--  1 admin  staff  2221 20 Nov 03:39 sample.pdf
```
- run2-pkg-offline: **CLEAN ROOM PASS (13 checks)**
- run3-pkg-upgrade: **CLEAN ROOM PASS (13 checks)**
