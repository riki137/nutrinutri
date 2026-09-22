# Flatpak packaging

`sk.popelis.nutrinutri.yml` repackages the already-built `flutter build linux
--release` bundle — it doesn't compile Flutter inside the sandbox. This is the
same approach real Flutter apps on Flathub use (e.g. LocalSend), and it's why
CI can smoke-test the packaging on every PR without a slow from-source build.

## How the source pin works

`nutrinutri-source.json` is a single `archive` source spliced into the
manifest (flatpak-builder supports referencing an external file by name in a
module's `sources:` list). Two different versions of it exist:

- **Committed version** (what you see in git): pins the latest tagged GitHub
  release's `nutrinutri-linux.tar.gz`. This is what gets submitted to
  Flathub — their build bot has no network during the actual build, only
  during source fetching, so the source must be a stable, checksummed URL.
- **CI-generated version**: both `ci.yml`'s smoke job and `release.yml`'s
  release job overwrite this file in the runner's working copy (never
  committed) to point at the bundle they just built locally, so the Flatpak
  always reflects the code under test/release, not a stale prior release.

## Bumping the pinned release

After cutting a new release (tag pushed, `release.yml` published the assets):

```sh
VERSION=v1.3.3
curl -sL -o /tmp/nutrinutri-linux.tar.gz \
  "https://github.com/riki137/nutrinutri/releases/download/$VERSION/nutrinutri-linux.tar.gz"
SHA256=$(sha256sum /tmp/nutrinutri-linux.tar.gz | cut -d' ' -f1)
cat > flatpak/nutrinutri-source.json <<EOF
[
  {
    "type": "archive",
    "url": "https://github.com/riki137/nutrinutri/releases/download/$VERSION/nutrinutri-linux.tar.gz",
    "sha256": "$SHA256"
  }
]
EOF
```

Also bump the `<release>` entry in `sk.popelis.nutrinutri.metainfo.xml`. This
bump is what you submit as the update PR to `flathub/flathub` once the app is
there (updates never go through the full submission review again).

## Testing locally (needs a Linux box with flatpak-builder)

```sh
flatpak install -y flathub org.flatpak.Builder org.gnome.Platform//51 org.gnome.Sdk//51
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest flatpak/sk.popelis.nutrinutri.yml
flatpak run --command=flathub-build org.flatpak.Builder --install flatpak/sk.popelis.nutrinutri.yml
flatpak run sk.popelis.nutrinutri
```

## Submitting to Flathub

1. Swap the two placeholder screenshots in `sk.popelis.nutrinutri.metainfo.xml`
   for real Linux desktop screenshots (the current ones are the mobile
   screenshots from the landing page — fine for now, but reviewers expect
   platform-accurate screenshots).
2. Run the lint/build steps above and fix anything it flags.
3. Fork `flathub/flathub` **without** "Copy the master branch only", then:
   ```sh
   git clone --branch=new-pr git@github.com:<you>/flathub.git && cd flathub
   git checkout -b nutrinutri new-pr
   cp ../nutrinutri/flatpak/sk.popelis.nutrinutri.yml .
   cp ../nutrinutri/flatpak/sk.popelis.nutrinutri.desktop .
   cp ../nutrinutri/flatpak/sk.popelis.nutrinutri.metainfo.xml .
   cp ../nutrinutri/flatpak/nutrinutri-source.json .
   git add . && git commit -m "Add sk.popelis.nutrinutri" && git push -u origin nutrinutri
   ```
4. Open a PR against `flathub/flathub`'s `new-pr` branch (not `master`),
   titled "Add sk.popelis.nutrinutri".
5. **After acceptance**, verify domain ownership from the Flathub Developer
   Portal: it issues a one-time token for this app that must be placed at
   `https://popelis.sk/.well-known/org.flathub.VerifiedApps.txt` — note that's
   the bare `popelis.sk` domain (the app-id minus its last label, reversed),
   not the `nutrinutri.popelis.sk` landing subdomain. Skippable — verification
   just adds a checkmark, it isn't required to publish.

Full docs: <https://docs.flathub.org/docs/for-app-authors/submission>.
