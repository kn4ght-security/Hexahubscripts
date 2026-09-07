Astroid Hub PRIVATE – New UI (Linoria style)

Files:
  Library.lua       – Main UI library (with Icon support)
  ThemeManager.lua  – Themes addon
  SaveManager.lua   – Config save/load addon
  AstroidHub.lua    – Main script (all features)
  loader.lua        – Loads everything in order
  ah_logo.png       – AH logo (shown top-right in title bar)

Mobile support
--------------
YES. The library detects touch devices (Library.IsMobile) and uses:
  • Touch drag for moving the window
  • Touch resize grip
  • Larger scrollbars / window size on mobile
  • Touch-friendly input on toggles, sliders, dropdowns

The Controls tab also has Mobile / PC / Controller / VR for the game itself.

Logo (top-right)
----------------
ah_logo.png is placed in the title bar (top-right) next to "Astroid Hub PRIVATE".
Uses getcustomasset when the file is available in the executor workspace.
You can also host the PNG and set a URL in resolveLogo() inside AstroidHub.lua.

How to use
----------
1. Host the files (or put them where your executor can readfile / getcustomasset)
2. Set BASE URL inside loader.lua if using HttpGet
3. Run:
     loadstring(game:HttpGet("YOUR_URL/loader.lua"))()

Features kept
-------------
• Combat, TP Packs, Skins, Controls, Visual, Spoof, Info
• Settings tab: Themes + config save/load
• All original feature logic preserved
