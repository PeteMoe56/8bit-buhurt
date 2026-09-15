shader_type canvas_item;
// KIT REPLACE — a port of Retro Bowl's `sh_ColorReplaceBlend`, read out of the
// shipping build (docs/RetroBowl-Art-Spec.pdf §2).
//
// A fighter sprite is NOT coloured artwork. It is a mask painted in nine flat
// key colours, and this swaps each key for the club's own kit at draw time. One
// set of drawings serves every club in the pyramid, home and away, for ever —
// which is the answer to the objection docs/ART.md raised against fighter
// sprites in the first place: *"a fixed sprite cannot carry a colour the player
// picked."* It can, if it never carried a colour to begin with.
//
// THREE RULES FOR WHOEVER DRAWS THE SPRITES, and all three are enforced here
// rather than asked for politely:
//
//   1. OPAQUE PIXELS ONLY. The test below is `a == 1.0`, exactly as theirs is.
//      An anti-aliased edge, a soft shadow, a 50%-alpha pixel keeps its key
//      colour and renders as raw magenta on screen. This is why the style has no
//      anti-aliasing anywhere: the palette system forbids it.
//   2. EXACT HEX. EPS is 0.009 — about 2/255. A key one step off is not
//      replaced. Colours are typed, never eyedropped, never saved through a
//      lossy step.
//   3. THE SHADE IS ITS OWN SLOT. steel and steel_b are two uniforms, not one
//      colour darkened. The club picks both.
//
// Skin is deliberately absent from the nine — the men are in helms — and the
// slot it frees went to the second tincture of the surcoat, which is what a club
// is actually recognised by.

const float EPS = 0.009;

// The keys, as painted in the PNG. Defaults are the published spec; they are
// uniforms so a mask can be proofed without re-exporting.
uniform vec3 key_surcoat_a : source_color = vec3(1.0, 0.0, 1.0);
uniform vec3 key_surcoat_b : source_color = vec3(0.5, 0.0, 0.5);
uniform vec3 key_trim      : source_color = vec3(1.0, 1.0, 0.0);
uniform vec3 key_helm      : source_color = vec3(1.0, 0.0, 0.0);
uniform vec3 key_steel     : source_color = vec3(0.5, 0.5, 1.0);
uniform vec3 key_steel_b   : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 key_leather   : source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 key_leather_b : source_color = vec3(0.0, 0.5, 0.0);
uniform vec3 key_mark      : source_color = vec3(0.5, 0.5, 0.5);

// This club's kit. Set per draw.
uniform vec3 to_surcoat_a : source_color = vec3(1.0, 0.0, 1.0);
uniform vec3 to_surcoat_b : source_color = vec3(0.5, 0.0, 0.5);
uniform vec3 to_trim      : source_color = vec3(1.0, 1.0, 0.0);
uniform vec3 to_helm      : source_color = vec3(1.0, 0.0, 0.0);
uniform vec3 to_steel     : source_color = vec3(0.5, 0.5, 1.0);
uniform vec3 to_steel_b   : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 to_leather   : source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 to_leather_b : source_color = vec3(0.0, 0.5, 0.0);
uniform vec3 to_mark      : source_color = vec3(0.5, 0.5, 0.5);

bool is_key(vec3 p, vec3 k) {
	return all(greaterThanEqual(p, k - vec3(EPS))) && all(lessThanEqual(p, k + vec3(EPS)));
}

void fragment() {
	vec4 px = texture(TEXTURE, UV);
	if (px.a == 1.0) {
		// Ordered largest area first, the way theirs is — the common case exits
		// the chain soonest and a fighter is mostly surcoat and plate.
		if      (is_key(px.rgb, key_surcoat_a)) px.rgb = to_surcoat_a;
		else if (is_key(px.rgb, key_steel))     px.rgb = to_steel;
		else if (is_key(px.rgb, key_surcoat_b)) px.rgb = to_surcoat_b;
		else if (is_key(px.rgb, key_steel_b))   px.rgb = to_steel_b;
		else if (is_key(px.rgb, key_helm))      px.rgb = to_helm;
		else if (is_key(px.rgb, key_leather))   px.rgb = to_leather;
		else if (is_key(px.rgb, key_leather_b)) px.rgb = to_leather_b;
		else if (is_key(px.rgb, key_trim))      px.rgb = to_trim;
		else if (is_key(px.rgb, key_mark))      px.rgb = to_mark;
		// Everything else — black, near-black, the one white spec — is fixed and
		// falls through untouched. That is the whole of the rest of the palette.
	}
	COLOR = px;
}
