# Expert Meeting Viewer Imagegen Prompts

Version: v1.0.0

Use these prompts to generate the visual foundation for the expert meeting viewer. The first priority is spatial correctness: one moderator seat at the top head of a vertical long table, ten discussion seats on the left and right sides.

## Prompt A: Empty Meeting Room Base

Use this first. It should generate the background image that the web viewer uses for reverse positioning.

```text
Use case: productivity-visual
Asset type: 2D web app meeting viewer background
Primary request: Generate an empty stylized expert-panel meeting room background with a vertical long conference table.
Scene/backdrop: a clean, bright, minimal meeting room inspired by Tencent Marvis-style white office visuals: soft white and light gray surfaces, gentle depth, blurred floor shadows, crisp UI-friendly shapes, no clutter.
Subject: one vertical long conference table centered in the canvas, viewed from a high front oblique orthographic angle. The table runs from the top of the image toward the bottom. Place exactly one moderator seat at the top head of the table, centered on the short edge. Place exactly ten discussion seats total: five seats on the left side of the table and five seats on the right side of the table. The side seats must face inward toward the table. Leave all seats empty, with no people or animals.
Style/medium: polished 2D illustration with soft 3D-like office shading, clean product UI asset, subtle realistic shadows, white desk-and-chair language similar in mood to the provided Marvis reference, but original composition and not a copy.
Composition/framing: 16:10 landscape canvas, table centered, enough empty margin around every chair for later character overlays. The moderator seat is clearly separated at the top head position. The ten side seats are evenly spaced and aligned along the long edges of the table. The scene should read immediately as a formal meeting layout.
Lighting/mood: bright diffuse studio lighting from upper left, soft contact shadows under table and chairs, calm professional atmosphere.
Color palette: mostly white, warm light gray, very pale blue-gray shadows, small optional muted blue screen accents only if needed. Avoid dark background.
Materials/textures: smooth matte white table, light gray chairs, subtle glass or acrylic highlights, soft floor reflections only if very subtle.
Text (verbatim): no text.
Constraints: exactly 11 seating positions total: 1 moderator at the top head, 10 discussion seats on the sides. No people, no animals, no logos, no readable text, no watermarks. Do not make a round table. Do not make a horizontal table. Do not place seats at the bottom head of the table. Do not crop any chair. Do not use a dark UI dashboard style. Keep clear empty overlay space for web animation.
Avoid: messy perspective, fisheye lens, crowded office, random laptops, extra chairs, duplicated tables, people, mascots, brand marks, decorative gradients, dramatic cinematic lighting.
```

Recommended output size:

- `1536x960` or `1920x1200` if available.
- If only common sizes are available, use `1536x1024` and crop/pad in the web layer.

## Prompt B: Meeting Room With Seat Markers

Use this if Prompt A makes seat positions ambiguous.

```text
Use case: productivity-visual
Asset type: 2D web app meeting viewer layout reference
Primary request: Generate the same empty vertical long-table expert meeting room, but add very subtle non-text seat markers.
Scene/backdrop: clean white meeting room, soft office shadows, original Marvis-inspired visual mood.
Subject: one centered vertical long conference table, one moderator chair at the top head, exactly five chairs on the left side and five chairs on the right side. Add a small pale circular floor marker behind each chair to make all 11 seating positions easy to locate for UI overlay. The markers must be abstract dots only, no numbers and no text.
Style/medium: polished 2D illustration, soft 3D-like office shading, clean UI background asset.
Composition/framing: 16:10 landscape, table centered, chairs evenly spaced, no chair cropped, large enough margin around each seat for animated character sprites.
Lighting/mood: bright diffuse lighting, soft contact shadows.
Color palette: white, light gray, pale blue-gray, very subtle marker tint.
Text (verbatim): no text.
Constraints: exactly 11 seating positions, empty room, no people, no animals, no logos, no words, no watermarks. Vertical long table only.
Avoid: round table, horizontal table, bottom head seat, extra chairs, strong labels, dark background, clutter.
```

## Prompt C: Table And Chairs Cutout

Use this only after the base room is approved, when a separate foreground furniture layer is useful.

```text
Use case: background-extraction
Asset type: foreground furniture layer for a 2D web app meeting viewer
Primary request: Generate a clean isolated vertical long conference table with exactly 11 empty chairs arranged for an expert-panel meeting.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal.
Subject: one white vertical long conference table, one moderator chair at the top head, five chairs along the left side, five chairs along the right side. No bottom head chair. Chairs face inward toward the table.
Style/medium: polished 2D office illustration with soft 3D-like shading, matching a clean Marvis-inspired white office visual mood.
Composition/framing: full object visible, generous padding, centered, 16:10 landscape.
Lighting/mood: soft studio lighting on the object only, but no cast shadow touching the green background.
Color palette: white and light gray furniture, pale blue-gray shading.
Text (verbatim): no text.
Constraints: exactly 11 chairs, no people, no animals, no logos, no watermarks, background must be one uniform #00ff00 color with no gradient, no shadows, no floor plane, no texture. Do not use #00ff00 anywhere in the furniture.
Avoid: extra chairs, round table, horizontal table, cropped furniture, dark materials.
```

## Reverse-Positioning Notes

After the base image is generated and approved:

1. Save it as `assets/expert-meeting-viewer/art/meeting-room-base-v1.png`.
2. Measure the 11 anchor points:
   - `host`: center of the moderator chair at the top head.
   - `left-1` to `left-5`: top-to-bottom left seats.
   - `right-1` to `right-5`: top-to-bottom right seats.
3. Store anchors as normalized percentages so the layout survives responsive scaling.
4. Let HTML/CSS/JS draw characters, speech bubbles, challenge lines, and consensus UI above the background image.

Suggested anchor JSON shape:

```json
{
  "version": "1.0.0",
  "image": "art/meeting-room-base-v1.png",
  "anchors": {
    "host": { "x": 50, "y": 13, "facing": "down" },
    "left-1": { "x": 31, "y": 25, "facing": "right" },
    "left-2": { "x": 31, "y": 37, "facing": "right" },
    "left-3": { "x": 31, "y": 49, "facing": "right" },
    "left-4": { "x": 31, "y": 61, "facing": "right" },
    "left-5": { "x": 31, "y": 73, "facing": "right" },
    "right-1": { "x": 69, "y": 25, "facing": "left" },
    "right-2": { "x": 69, "y": 37, "facing": "left" },
    "right-3": { "x": 69, "y": 49, "facing": "left" },
    "right-4": { "x": 69, "y": 61, "facing": "left" },
    "right-5": { "x": 69, "y": 73, "facing": "left" }
  }
}
```
