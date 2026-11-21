
brew:
```text
To force the link and overwrite all conflicting files:
  brew link --overwrite sdl2-compat

To list all files that would be deleted:
  brew link --overwrite sdl2-compat --dry-run

Possible conflicting files are:
/opt/homebrew/bin/sdl2-config -> /opt/homebrew/Cellar/sdl2/2.32.10/bin/sdl2-config
==> Caveats
==> knaif
Download the AI model before the first run (~2.5 GB, into ~/.knaif/models):
  knaif models pull knaif-qwen3-4b-v2

The documents skill can use these optional tools:
  brew install ghostscript tesseract
  brew install --cask libreoffice

To see what each skill still needs:
  knaif skills deps
knaif 1.3.0 (inference: llama.cpp)
documents    native:knaif-skill-documents Local document toolkit for inspecting, extracting, finding, converting, combining, and compressing files.
ffmpeg       native:knaif-skill-ffmpeg    FFmpeg-powered media workflow assistant — convert, compress, resize, extract, and prepare video/audio for platforms.
rotate pages
✓ wrote /private/var/folders/bj/lb73mxgd3fl6kmhl10bkk5m80000gn/T/tmp.7v3gNbYlZb/sample-rotated.pdf
exit 0
```
- **the cask installs 1.4.0 and a real request runs**
