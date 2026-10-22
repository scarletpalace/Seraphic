# Seraphic (Etterna theme)

An Etterna theme inspired by the LR2 skin "Seraphic" by NiGHTS. / Graphics by Studio Blue Moon.
Built on top of the 'Til Death theme layout.

Art taken from the LR2 skin (not original to this theme; credit belongs to its authors):
- Fractal background (Graphics/_OptionsScreen.png, recolored)
- Crystal corner ornament (Graphics/seraphic_corner.png)
- "Music Select" logo (Graphics/seraphic_title.png)
- Magic circle (Graphics/seraphic_circle.png)
- Filigree ornament strip (Graphics/seraphic_filigree.png)
- STAGE CLEARED / STAGE FAILED emblems (Graphics/seraphic_cleared.png, seraphic_failed.png)

Install: put the "Seraphic" folder in Etterna's Themes folder, then pick it in Options > Theme.
If colors look unchanged, delete your saved colorConfig.lua (in Save/) so the new defaults apply.

Song select update: wheel bars, selected-bar frame and tab feathers now use sprites cut from the LR2 skin
(Graphics/seraphic_bar_*.png, seraphic_barsel_*.png); seraphic_feather.png is a generated feather used behind the tabs.


## Fonts (converted from the LR2 skin)
The three LR2 fonts were converted to Etterna bitmap fonts (Fonts/seraphic/):
- titlefont  -> big text      (Fonts/Common Large.redir, pack/sort names on the wheel)
- artistfont -> middle text   (song title/artist on the wheel and evaluation screen, pack progress on the wheel)
- opfont     -> small text    (Fonts/Common Normal.redir = everything else)
Characters missing from a font (e.g. accented Latin) fall back to the previous Bokuta Gothic font.
Sizes are matched to the old fonts, so existing zoom values keep working. The op font is stretched 2x3.5 per pixel.

To go back to the old fonts, set the contents of
  Fonts/Common Large.redir  to  bokutachinogothic2bold/doubleres/48px
  Fonts/Common Normal.redir to  bokutachinogothic2bold/doubleres/24px
and delete Fonts/TextBanner text.redir and the Fonts/MusicWheelItem *.redir files
(and set the wheel Section/Sort zoom in metrics.ini back from 0.44 to 0.875).

## Manip Factor
The result screen shows the Manip Factor (MF) of 4k plays, ported from ManipFactorEtterna by MaidOfFire
(https://github.com/MaidOfFire/ManipFactorEtterna): the last line of the stats box, colored green (clean) to red (heavy manip).
Hover it to split it into left and right hand; the offset plot tooltip also shows the MF up to the cursor.
The calculation is in Scripts/08 ManipFactor.lua (restart the game after updating the theme so it loads).
