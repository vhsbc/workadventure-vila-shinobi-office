# WorkAdventure Prototype

Standalone repository for a WorkAdventure prototype hosted from `c:\SAP\GIT\SAP\workadventure`.

This project is intentionally separate from `FlowMate`. It contains a light, original "ninja village office" environment designed for the WorkAdventure free plan.

## Current scope

- 10 individual workstations
- 1 shared table for quick syncs
- 1 team meeting room
- 1 private `1:1` feedback room
- 2 silent work bays

## Key files

- `index.html`: public landing page for GitHub Pages
- `maps/ninja-office-prototype.json`: main WorkAdventure map for public hosting
- `maps/ninja-office-prototype.tmj`: Tiled-oriented version of the same map
- `assets/tiles/ninja-office-tiles.png`: custom prototype tileset
- `tools/New-PrototypeMap.ps1`: regenerates the map, tileset, and SVG preview
- `docs/layout.md`: functional layout notes

## Regenerate assets

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\New-PrototypeMap.ps1
```

## Publish with GitHub Pages

1. Create a new public GitHub repository for this folder.
2. Add the remote:

```powershell
git remote add origin https://github.com/<your-user>/<your-repo>.git
```

3. Push the `main` branch:

```powershell
git push -u origin main
```

4. In GitHub, enable Pages from the `main` branch root.

After Pages is active, the public site URL will be:

```text
https://<your-user>.github.io/<your-repo>/
```

That landing page automatically computes the WorkAdventure test URL for:

```text
https://<your-user>.github.io/<your-repo>/maps/ninja-office-prototype.json
```

## Direct WorkAdventure URL pattern

```text
https://play.workadventu.re/_/global/<your-user>.github.io/<your-repo>/maps/ninja-office-prototype.json
```

## Next steps

1. Open the map in Tiled and refine decoration.
2. Push the standalone repository to GitHub.
3. Share the GitHub Pages URL or the direct WorkAdventure URL with the team.
