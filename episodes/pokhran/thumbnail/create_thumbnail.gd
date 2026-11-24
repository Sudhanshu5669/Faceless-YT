extends SceneTree
## Compose the Pokhran thumbnails from clean full-size frames of the episode (storyboard stills, no captions; no
## generated imagery):
##   pokhran_youtube_thumbnail.png  1280x720: the device with its "White House" sticker | the desert heaving
##   pokhran_shorts_cover.png       1080x1920: the dust column towering over the team, the sticker in a round inset
## The round inset on the cover shows the sticker image itself (library/logos/pokhran/generated/sticker_white_house.png,
## the one on the device in lid_wh; a latch on the device crosses it in every frame).
## Frames: device_frame.png (lid_wh, mid), blast_frame_late.png (desert_jumps, end), blast_frame.png (desert_jumps, mid)
## from `python pipeline/tf.py storyboard pokhran --shots desert_jumps,lid_wh --scale 1`.
## Run: godot --path godot --script res://../episodes/pokhran/thumbnail/create_thumbnail.gd

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/pokhran/thumbnail"
# The sticker on the device in device_frame.png (pixels): centre and radius of the round inset's crop.
const STICKER := Vector2(530, 565)
const STICKER_R := 120.0


class Draw:
	static func fonts() -> Array:
		var body := FontFile.new()
		body.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/baloo2/Baloo2.ttf"))
		var title := FontFile.new()
		title.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/lilita_one/LilitaOne-Regular.ttf"))
		var heavy := FontVariation.new()
		heavy.base_font = body
		heavy.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
		title.fallbacks = [heavy, body]
		return [title, body]

	static func outlined(ci: CanvasItem, font: Font, at: Vector2, text: String, width: float, size: int, col: Color, outline: int) -> void:
		ci.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline, Color("#0c0d10"))
		ci.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)

	## A round inset: the region of `tex` centred on `src` (radius `src_r`), drawn as a disc at `at` (radius r), with a ring.
	static func inset(ci: CanvasItem, tex: Texture2D, src: Vector2, src_r: float, at: Vector2, r: float, ring: Color) -> void:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var sz := tex.get_size()
		for k in 72:
			var a := TAU * k / 72.0
			var d := Vector2(cos(a), sin(a))
			pts.append(at + d * r)
			uvs.append((src + d * src_r) / sz)
		ci.draw_colored_polygon(pts, Color.WHITE, uvs, tex)
		ci.draw_arc(at, r + 6.0, 0.0, TAU, 96, Color("#0c0d10"), 16.0, true)
		ci.draw_arc(at, r + 4.0, 0.0, TAU, 96, ring, 8.0, true)


class Landscape extends Node2D:
	var device: ImageTexture
	var blast: ImageTexture
	var title: Font
	var body: Font

	func _init() -> void:
		device = ImageTexture.create_from_image(Image.load_from_file(OUT + "/device_frame.png"))
		blast = ImageTexture.create_from_image(Image.load_from_file(OUT + "/blast_frame.png"))
		var f: Array = Draw.fonts()
		title = f[0]
		body = f[1]

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("#0d0e12"))
		# Left: the device in the vault, the sticker in the upper third. Right: the desert heaving, the team watching.
		draw_texture_rect_region(device, Rect2(0, 0, 636, 720), Rect2(70, 260, 920, 1041))
		draw_texture_rect_region(blast, Rect2(644, 0, 636, 720), Rect2(40, 640, 1000, 1132))
		draw_rect(Rect2(636, 0, 8, 720), Color("#ffd45e"))
		for i in 20:
			var a := 0.8 * (1.0 - float(i) / 20.0)
			draw_rect(Rect2(0, i * 7, 1280, 7), Color(0.03, 0.03, 0.05, a))
			draw_rect(Rect2(0, 720 - (i + 1) * 12, 1280, 12), Color(0.03, 0.03, 0.05, a))
		Draw.outlined(self, title, Vector2(0, 96), "INDIA BLEW UP", 1280, 88, Color("#fffdf4"), 12)
		Draw.outlined(self, title, Vector2(0, 672), "THE WHITE HOUSE", 1280, 104, Color("#ffd45e"), 14)


class Vertical extends Node2D:
	var blast: ImageTexture
	var sticker: ImageTexture
	var title: Font
	var body: Font

	func _init() -> void:
		blast = ImageTexture.create_from_image(Image.load_from_file(OUT + "/blast_frame_late.png"))
		sticker = ImageTexture.create_from_image(Image.load_from_file(OUT + "/../../../library/logos/pokhran/generated/sticker_white_house.png"))
		var f: Array = Draw.fonts()
		title = f[0]
		body = f[1]

	func _draw() -> void:
		draw_texture_rect(blast, Rect2(0, 0, 1080, 1920), false)
		for i in 24:
			var a := 0.75 * (1.0 - float(i) / 24.0)
			draw_rect(Rect2(0, i * 16, 1080, 16), Color(0.02, 0.02, 0.04, a))
		for i in 14:
			var a := 0.55 * (1.0 - float(i) / 14.0)
			draw_rect(Rect2(0, 1920 - (i + 1) * 14, 1080, 14), Color(0.02, 0.02, 0.04, a))
		Draw.outlined(self, title, Vector2(0, 220), "INDIA BLEW UP", 1080, 132, Color("#fffdf4"), 16)
		Draw.outlined(self, title, Vector2(0, 362), "THE WHITE HOUSE", 1080, 116, Color("#ffd45e"), 16)
		# The joke: the code name on the device, in a round inset over the sky.
		var c := Vector2(820, 640)
		draw_circle(c, 150.0, Color("#2b2e33"))
		draw_circle(c, 140.0, Color("#3a3e44"))
		var ss := sticker.get_size()
		var k := 240.0 / maxf(ss.x, ss.y)
		draw_texture_rect(sticker, Rect2(c - ss * k * 0.5, ss * k), false)
		draw_arc(c, 156.0, 0.0, TAU, 96, Color("#0c0d10"), 16.0, true)
		draw_arc(c, 154.0, 0.0, TAU, 96, Color("#ffd45e"), 8.0, true)
		Draw.outlined(self, body, Vector2(560, 852), "CODE NAME", 520, 50, Color("#fffdf4"), 10)
		Draw.outlined(self, body, Vector2(0, 1630), "POKHRAN, 11 MAY 1998", 1080, 58, Color("#e9e4d6"), 10)


var _stage := 0


func _initialize() -> void:
	_show(Landscape.new(), Vector2i(1280, 720))


func _show(node: Node2D, size: Vector2i) -> void:
	for c in root.get_children():
		c.queue_free()
	DisplayServer.window_set_size(size)
	root.size = size
	root.content_scale_size = size
	root.add_child(node)
	call_deferred("_capture")


func _capture() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var name := "pokhran_youtube_thumbnail.png" if _stage == 0 else "pokhran_shorts_cover.png"
	if img.save_png(OUT + "/" + name) != OK:
		printerr("Failed to save ", name)
		quit(1)
		return
	print("Saved: ", OUT + "/" + name)
	_stage += 1
	if _stage == 1:
		_show(Vertical.new(), Vector2i(1080, 1920))
	else:
		quit()
