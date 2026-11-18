extends SceneTree
## Compose the Mangalyaan thumbnails from frames of the final render (no generated imagery):
##   mangalyaan_youtube_thumbnail.png  1280x720: the auto in the Ahmedabad market (₹10/KM) vs the same auto at Mars (₹7/KM)
##   mangalyaan_shorts_cover.png       1080x1920: the auto floating in front of Mars
## Frames: street_frame.png (2.4 s) and space_frame.png (5.6 s), from renders/mangalyaan_picture.mp4.
## Run: godot --path godot --script res://../episodes/mangalyaan/thumbnail/create_thumbnail.gd   (see README in this folder)

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/mangalyaan/thumbnail"


class Draw:
	static func fonts() -> Array:
		var body := FontFile.new()
		body.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/baloo2/Baloo2.ttf"))
		var title := FontFile.new()
		title.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/lilita_one/LilitaOne-Regular.ttf"))
		# Lilita One has no ₹: fall back to Baloo 2.
		var heavy := FontVariation.new()
		heavy.base_font = body
		heavy.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
		title.fallbacks = [heavy, body]
		return [title, body]


	static func outlined(ci: CanvasItem, font: Font, at: Vector2, text: String, width: float, size: int, col: Color, outline: int) -> void:
		ci.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline, Color("#0c0d10"))
		ci.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


class Landscape extends Node2D:
	var street: ImageTexture
	var space: ImageTexture
	var title: Font
	var body: Font

	func _init() -> void:
		street = ImageTexture.create_from_image(Image.load_from_file(OUT + "/street_frame.png"))
		space = ImageTexture.create_from_image(Image.load_from_file(OUT + "/space_frame.png"))
		var f: Array = Draw.fonts()
		title = f[0]
		body = f[1]

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("#0d0e12"))
		# Two unaltered stills, cropped to fill each half.
		draw_texture_rect_region(street, Rect2(0, 0, 636, 720), Rect2(0, 330, 1080, 1222))
		draw_texture_rect_region(space, Rect2(644, 0, 636, 720), Rect2(0, 420, 1080, 1222))
		draw_rect(Rect2(636, 0, 8, 720), Color("#ffd45e"))
		# Scrims top and bottom so the words read at phone size.
		for i in 20:
			var a := 0.8 * (1.0 - float(i) / 20.0)
			draw_rect(Rect2(0, i * 7, 1280, 7), Color(0.03, 0.03, 0.05, a))
			draw_rect(Rect2(0, 720 - (i + 1) * 12, 1280, 12), Color(0.03, 0.03, 0.05, a))
		Draw.outlined(self, title, Vector2(0, 92), "AUTO RIDE", 636, 64, Color("#fffdf4"), 10)
		Draw.outlined(self, title, Vector2(644, 92), "MARS", 636, 64, Color("#fffdf4"), 10)
		Draw.outlined(self, title, Vector2(0, 676), "₹10/KM", 636, 120, Color("#fffdf4"), 14)
		Draw.outlined(self, title, Vector2(644, 676), "₹7/KM", 636, 120, Color("#ffd45e"), 14)


class Vertical extends Node2D:
	var space: ImageTexture
	var title: Font
	var body: Font

	func _init() -> void:
		space = ImageTexture.create_from_image(Image.load_from_file(OUT + "/space_frame.png"))
		var f: Array = Draw.fonts()
		title = f[0]
		body = f[1]

	func _draw() -> void:
		draw_texture_rect(space, Rect2(0, 0, 1080, 1920), false)
		for i in 24:
			var a := 0.85 * (1.0 - float(i) / 24.0)
			draw_rect(Rect2(0, i * 16, 1080, 16), Color(0.02, 0.02, 0.04, a))
			draw_rect(Rect2(0, 1920 - (i + 1) * 18, 1080, 18), Color(0.02, 0.02, 0.04, a))
		Draw.outlined(self, title, Vector2(0, 230), "INDIA WENT", 1080, 138, Color("#fffdf4"), 16)
		Draw.outlined(self, title, Vector2(0, 380), "TO MARS", 1080, 138, Color("#fffdf4"), 16)
		Draw.outlined(self, title, Vector2(0, 1640), "FOR ₹7/KM", 1080, 150, Color("#ffd45e"), 18)
		Draw.outlined(self, body, Vector2(0, 1745), "CHEAPER THAN AN AUTO RIDE", 1080, 54, Color("#e9e4d6"), 10)


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
	var name := "mangalyaan_youtube_thumbnail.png" if _stage == 0 else "mangalyaan_shorts_cover.png"
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
