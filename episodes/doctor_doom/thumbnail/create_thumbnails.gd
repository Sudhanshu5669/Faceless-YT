extends SceneTree
## Four 1280x720 YouTube thumbnails for doctor_doom, composed from frames of the final render (no generated imagery).
##   thumb_a_why_him.png      Hall H: toon RDJ unmasked under green beams, his face on the screen. "WHY HIM?"
##   thumb_b_new_mask.png     split: Iron Man's gold helmet | the Doom mask. RDJ's real Hall H line "NEW MASK. SAME TASK."
##   thumb_c_doom.png         the hooded Doom close-up, his shadow on the wall. No text.
##   thumb_d_devil.png        hell: Doom's silhouette firing at the Devil. "EVERY YEAR." (line d6: he fights the Devil every year)
## Frames (from renders/doctor_doom_picture.mp4, no captions): unmask 19.8 s (hall_quote), helmet 25.1 s (gal_helmet),
## doom 434.5 s (gal_eye), hell 285.9 s (hell_fight). Re-extract with:
##   ffmpeg -ss 19.8 -i renders/doctor_doom_picture.mp4 -frames:v 1 thumbnail/unmask_frame.png   (etc.)
## Run: godot --path godot --script res://../episodes/doctor_doom/thumbnail/create_thumbnails.gd

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/doctor_doom/thumbnail"
const NAMES := ["thumb_a_why_him.png", "thumb_b_new_mask.png", "thumb_c_doom.png", "thumb_d_devil.png"]
const W := 1280
const H := 720
const YELLOW := Color("#ffd400")
const WHITE := Color("#fffdf4")
const INK := Color("#07080a")


class Thumb extends Node2D:
	var kind := 0
	var font: FontFile
	var tex := {}

	func _init(k: int) -> void:
		kind = k
		for n in ["unmask", "helmet", "doom", "hell"]:
			tex[n] = ImageTexture.create_from_image(Image.load_from_file(OUT + "/" + n + "_frame.png"))
		font = FontFile.new()
		font.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/lilita_one/LilitaOne-Regular.ttf"))

	## Big outlined word: a soft drop shadow, a thick ink outline, then the fill.
	func _word(at: Vector2, text: String, width: float, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
		draw_string_outline(font, at + Vector2(0, 8), text, align, width, size, size / 5 + 6, Color(0, 0, 0, 0.55))
		draw_string_outline(font, at, text, align, width, size, size / 6 + 4, INK)
		draw_string(font, at, text, align, width, size, col)

	## Darken toward one edge so the words read at phone size.
	func _scrim(rect: Rect2, vertical: bool, from_a: float, to_a: float) -> void:
		var steps := int(rect.size.y if vertical else rect.size.x)  # 1-px bands: no visible steps
		for i in steps:
			var t := float(i) / float(steps - 1)
			var a := lerpf(from_a, to_a, t)
			if vertical:
				draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * i / steps, rect.size.x, rect.size.y / steps + 1), Color(0, 0, 0, a))
			else:
				draw_rect(Rect2(rect.position.x + rect.size.x * i / steps, rect.position.y, rect.size.x / steps + 1, rect.size.y), Color(0, 0, 0, a))

	func _vignette(strength: float) -> void:
		# 1-px rings, so no visible steps
		for i in 160:
			var a := strength * pow(1.0 - float(i) / 160.0, 2.5)
			var m := float(i) + 0.5
			draw_rect(Rect2(m, m, W - 2 * m, H - 2 * m), Color(0, 0, 0, a), false, 1.0)

	func _draw() -> void:
		draw_rect(Rect2(0, 0, W, H), INK)
		match kind:
			0:  # WHY HIM?
				draw_texture_rect_region(tex["unmask"], Rect2(0, 0, W, H), Rect2(160, 90, 1600, 900))
				_scrim(Rect2(700, 0, 580, H), false, 0.0, 0.55)
				_vignette(0.5)
				_word(Vector2(690, 250), "WHY", 590, 190, WHITE)
				_word(Vector2(690, 440), "HIM?", 590, 190, YELLOW)
			1:  # NEW MASK. SAME TASK.
				draw_texture_rect_region(tex["helmet"], Rect2(0, 0, 640, H), Rect2(650, 250, 636, 720))
				draw_texture_rect_region(tex["doom"], Rect2(640, 0, 640, H), Rect2(480, 160, 800, 900))
				# a lightning-crack divider: gold on the left edge, green on the right
				var pts := PackedVector2Array([Vector2(652, 0), Vector2(622, 200), Vector2(662, 330), Vector2(618, 480), Vector2(650, 720)])
				draw_polyline(pts, INK, 22.0)
				draw_polyline(pts, WHITE, 6.0)
				_scrim(Rect2(0, 0, W, 170), true, 0.75, 0.0)
				_scrim(Rect2(0, 520, W, 200), true, 0.0, 0.8)
				_word(Vector2(0, 128), "NEW MASK.", W, 118, WHITE)
				_word(Vector2(0, 676), "SAME TASK.", W, 128, YELLOW)
			2:  # the clean one
				draw_texture_rect_region(tex["doom"], Rect2(0, 0, W, H), Rect2(80, 150, 1520, 855))
				_vignette(0.7)
			3:  # EVERY YEAR.
				draw_texture_rect_region(tex["hell"], Rect2(0, 0, W, H), Rect2(0, 0, 1920, 1080))
				_scrim(Rect2(760, 0, 520, H), false, 0.0, 0.6)
				_word(Vector2(780, 150), "HE FIGHTS", 480, 84, WHITE)
				_word(Vector2(780, 240), "THE DEVIL", 480, 84, WHITE)
				_word(Vector2(780, 420), "EVERY", 480, 150, YELLOW)
				_word(Vector2(780, 570), "YEAR.", 480, 150, YELLOW)


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
