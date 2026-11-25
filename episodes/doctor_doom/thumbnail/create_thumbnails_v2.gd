extends SceneTree
## Round 2 of the doctor_doom thumbnails (the user didn't like round 1). 1280x720, from frames of the final picture.
## Two type styles: "cinema" (Georgia Bold + a soft glow, like the chapter cards) and "punch" (Impact, yellow/white).
##   thumb_e_one_world.png    Doom floating over the Earth           "ONE WORLD / UNDER DOOM"   (comic title, 2025)
##   thumb_f_throne.png       Doom on the throne, tech + magic       "SCIENTIST. SORCERER. KING."
##   thumb_g_gates.png        Doom's silhouette in a door of light   "THE MOST DANGEROUS / MAN IN MARVEL"
##   thumb_h_mirror.png       Iron Man's helmet, Doom's shadow       "IRON MAN'S / DARK / MIRROR"   (line r7)
##   thumb_i_galaxy.png       Doom holding a galaxy (punch)          "HE STOLE / A GOD'S / POWER"  (Secret Wars 1984, the Beyonder)
##   thumb_j_world.png        Doom over the Earth (punch)            "HE TOOK OVER / THE WORLD"     (One World Under Doom)
## Frames (doctor_doom_picture.mp4): earth 326.1 s, hands 274.8, gates 243.6, mirror 366.76, galaxy 298.9.
## Run: godot --path godot --script res://../episodes/doctor_doom/thumbnail/create_thumbnails_v2.gd

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/doctor_doom/thumbnail"
const NAMES := ["thumb_e_one_world.png", "thumb_f_throne.png", "thumb_g_gates.png", "thumb_h_mirror.png",
	"thumb_i_galaxy.png", "thumb_j_world.png"]
const W := 1280
const H := 720
const WHITE := Color("#f6f3ea")
const GREEN := Color("#7dff6a")
const YELLOW := Color("#ffd400")
const INK := Color("#050607")
const L := HORIZONTAL_ALIGNMENT_LEFT
const C := HORIZONTAL_ALIGNMENT_CENTER
const R := HORIZONTAL_ALIGNMENT_RIGHT


class Thumb extends Node2D:
	var kind := 0
	var serif: FontFile
	var impact: FontFile
	var tex := {}

	func _init(k: int) -> void:
		kind = k
		for n in ["earth", "hands", "gates", "mirror", "galaxy"]:
			tex[n] = ImageTexture.create_from_image(Image.load_from_file(OUT + "/" + n + "_frame.png"))
		serif = FontFile.new()
		serif.load_dynamic_font("C:/Windows/Fonts/georgiab.ttf")
		impact = FontFile.new()
		impact.load_dynamic_font("C:/Windows/Fonts/impact.ttf")

	## Cinematic title: a wide soft glow in `glow`, a thin dark edge, then the fill.
	func _cine(at: Vector2, text: String, width: float, size: int, col: Color, glow: Color, align := L) -> void:
		for r in [34, 24, 15, 8]:
			draw_string_outline(serif, at, text, align, width, size, r, Color(glow.r, glow.g, glow.b, 0.07))
		draw_string_outline(serif, at, text, align, width, size, 5, Color(0, 0, 0, 0.8))
		draw_string(serif, at, text, align, width, size, col)

	## Punchy: drop shadow, heavy ink outline, fill.
	func _punch(at: Vector2, text: String, width: float, size: int, col: Color, align := L) -> void:
		draw_string_outline(impact, at + Vector2(6, 8), text, align, width, size, size / 6 + 8, Color(0, 0, 0, 0.6))
		draw_string_outline(impact, at, text, align, width, size, size / 7 + 6, INK)
		draw_string(impact, at, text, align, width, size, col)

	func _scrim(rect: Rect2, vertical: bool, from_a: float, to_a: float) -> void:
		var steps := int(rect.size.y if vertical else rect.size.x)
		for i in steps:
			var a := lerpf(from_a, to_a, float(i) / float(steps - 1))
			if vertical:
				draw_rect(Rect2(rect.position.x, rect.position.y + i, rect.size.x, 1), Color(0, 0, 0, a))
			else:
				draw_rect(Rect2(rect.position.x + i, rect.position.y, 1, rect.size.y), Color(0, 0, 0, a))

	func _vignette(strength: float) -> void:
		for i in 160:
			var m := float(i) + 0.5
			draw_rect(Rect2(m, m, W - 2 * m, H - 2 * m), Color(0, 0, 0, strength * pow(1.0 - i / 160.0, 2.5)), false, 1.0)

	func _draw() -> void:
		draw_rect(Rect2(0, 0, W, H), INK)
		match kind:
			0:  # ONE WORLD UNDER DOOM
				draw_texture_rect_region(tex["earth"], Rect2(0, 0, W, H), Rect2(0, 120, 1440, 810))
				_scrim(Rect2(0, 0, 720, H), false, 0.6, 0.0)
				_vignette(0.6)
				_cine(Vector2(48, 300), "ONE WORLD", W, 84, WHITE, GREEN)
				_cine(Vector2(48, 395), "UNDER", W, 60, WHITE, GREEN)
				_cine(Vector2(44, 540), "DOOM", W, 156, GREEN, GREEN)
			1:  # SCIENTIST. SORCERER. KING.
				draw_texture_rect_region(tex["hands"], Rect2(0, 0, W, H), Rect2(160, 0, 1680, 945))
				_scrim(Rect2(0, 500, W, 220), true, 0.0, 0.85)
				_vignette(0.5)
				_cine(Vector2(0, 676), "SCIENTIST.  SORCERER.  KING.", W, 70, WHITE, GREEN, C)
			2:  # THE MOST DANGEROUS MAN IN MARVEL: tight on the silhouette, ink words on the blinding door
				draw_texture_rect_region(tex["gates"], Rect2(0, 0, W, H), Rect2(500, 300, 920, 518))
				_vignette(0.65)
				for r in [30, 18, 10]:
					draw_string_outline(serif, Vector2(0, 120), "THE MOST DANGEROUS", C, W, 74, r, Color(1, 1, 1, 0.12))
					draw_string_outline(serif, Vector2(0, 210), "MAN IN MARVEL", C, W, 74, r, Color(1, 1, 1, 0.12))
				draw_string(serif, Vector2(0, 120), "THE MOST DANGEROUS", C, W, 74, INK)
				draw_string(serif, Vector2(0, 210), "MAN IN MARVEL", C, W, 74, Color("#3a0d00"))
			3:  # IRON MAN'S DARK MIRROR
				draw_texture_rect_region(tex["mirror"], Rect2(0, 0, W, H), Rect2(500, 120, 1320, 742))
				_scrim(Rect2(700, 0, 580, H), false, 0.0, 0.6)
				_vignette(0.55)
				_cine(Vector2(700, 270), "IRON MAN'S", 580, 62, Color("#ffd27a"), Color("#ffb347"), C)
				_cine(Vector2(700, 395), "DARK", 580, 104, WHITE, GREEN, C)
				_cine(Vector2(700, 515), "MIRROR", 580, 104, GREEN, GREEN, C)
			4:  # HE STOLE A GOD'S POWER (punch)
				draw_texture_rect_region(tex["galaxy"], Rect2(0, 0, W, H), Rect2(300, 240, 1440, 810))
				_scrim(Rect2(0, 0, 620, H), false, 0.5, 0.0)
				_punch(Vector2(48, 230), "HE STOLE", 600, 120, WHITE)
				_punch(Vector2(48, 380), "A GOD'S", 600, 140, YELLOW)
				_punch(Vector2(48, 540), "POWER", 600, 150, YELLOW)
			5:  # HE TOOK OVER THE WORLD (punch)
				draw_texture_rect_region(tex["earth"], Rect2(0, 0, W, H), Rect2(0, 120, 1440, 810))
				_scrim(Rect2(0, 0, 720, H), false, 0.55, 0.0)
				_punch(Vector2(44, 250), "HE TOOK", 620, 130, WHITE)
				_punch(Vector2(44, 400), "OVER THE", 620, 130, WHITE)
				_punch(Vector2(44, 570), "WORLD", 620, 170, YELLOW)


var _i := 0


func _initialize() -> void:
	_show()


func _show() -> void:
	for c in root.get_children():
		c.queue_free()
	DisplayServer.window_set_size(Vector2i(W, H))
	root.size = Vector2i(W, H)
	root.content_scale_size = Vector2i(W, H)
	root.add_child(Thumb.new(_i))
	call_deferred("_capture")


func _capture() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.save_png(OUT + "/" + NAMES[_i]) != OK:
		printerr("Failed to save ", NAMES[_i])
		quit(1)
		return
	print("Saved: ", NAMES[_i])
	_i += 1
	if _i < NAMES.size():
		_show()
	else:
		quit()
