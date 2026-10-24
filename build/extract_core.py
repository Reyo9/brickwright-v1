# Builds public/core.js from the canonical brickwright.html, so the website and the Claude
# version share one prompt, one parser and one renderer. Re-run after editing brickwright.html.
import re, sys
src = open(sys.argv[1], encoding='utf8').read()
app = src[src.index("(function(){\n  // ---- static content ----"):]

def func(name):
    i = app.index("  function " + name + "(")
    j = app.index("\n  }\n", i)
    return app[i:j + 4]
def var_line(name):
    i = app.index("  var " + name + " = ")
    j = app.index("\n", i)
    return app[i:j + 1]
def var_block(name, end):
    i = app.index("  var " + name + " = ")
    j = app.index(end, i)
    return app[i:j + len(end)] + "\n"

parts = [
    var_block('details', "\n  ];"),
    var_line('chips'),
    var_block('EXAMPLE_SCRIPT', "].join('\\n');"),
    var_line('BRICK_COLOR_HEX'),
    var_line('BRICK_COLOR_FULL'),
    func('colorToHex'),
    "  var studTileTexture = null;\n",
    func('getStudTileTexture'),
    func('partHex'),
    func('polyGeo'),
    func('wedgePolys'),
    func('cornerWedgePolys'),
    func('shapeMesh'),
    var_line('SHAPE_CODES'),
    func('normalizePart'),
    func('parseResponse'),
    func('buildPrompt'),
]
treat = re.findall(r'<option value="([^"]+)">([^<]+)</option>', src[src.index('id="treatment"'):src.index('</select>', src.index('id="treatment"'))])
out = ("// AUTO-GENERATED from brickwright.html by build/extract_core.py — do not edit by hand.\n"
       "window.BWCore = (function(){\n"
       + "".join(parts) +
       "  var treatments = " + repr([{'value': v, 'label': l} for v, l in treat]).replace("'", '"') + ";\n"
       "  return { details: details, chips: chips, treatments: treatments, EXAMPLE_SCRIPT: EXAMPLE_SCRIPT,\n"
       "    BRICK_COLOR_FULL: BRICK_COLOR_FULL, shapeMesh: shapeMesh, parseResponse: parseResponse, buildPrompt: buildPrompt };\n"
       "})();\n")
open(sys.argv[2], 'w', encoding='utf8').write(out)
print('core.js', len(out), 'chars; treatments:', len(treat))
