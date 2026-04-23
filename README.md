# WorkAdventure Prototype

Standalone repository for a WorkAdventure prototype hosted from `c:\SAP\GIT\SAP\workadventure`.

This project is intentionally separate from `FlowMate`. It now contains a modern office prototype for all-day shared work, sized for a small team.

## Current scope

- 1 modern shared room for up to 10 people
- 1 central desk island with 10 notebook workstations
- 1 private booth inside the room
- 1 side coffee bar and support furniture
- visual refresh focused on a cleaner, less gamey office style

## Key files

- `index.html`: public landing page for GitHub Pages
- `maps/ninja-office-prototype.json`: main WorkAdventure map for public hosting
- `maps/ninja-office-prototype.tmj`: Tiled-oriented version of the same map
- `assets/tiles/modern-office-ground.png`: rendered office artwork sliced into map tiles
- `assets/tiles/modern-office-collision.png`: transparent collision tile
- `tools/New-PrototypeMap.ps1`: regenerates the map, tilesets, and SVG preview
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

1. Refine the desk island, booth, and support areas inside Tiled if needed.
2. Add a meeting interaction strategy only after the visual baseline is approved.
3. Share the GitHub Pages URL or the direct WorkAdventure URL with the team.
