extends SceneTree
## Cleaner Shorts-cover variants (the user didn't like the text and the badge on the first one). From clean frames only.
##   cover_a_clean.png     the dust column over the team, no text
##   cover_b_title.png     the same frame, only the title, smaller and quieter
##   cover_c_device.png    the device in the vault, its White House sticker the only "text"
##   cover_d_one_line.png  the device, one short line low in the frame
## Run: godot --path godot --script res://../episodes/pokhran/thumbnail/create_cover_variants.gd

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/pokhran/thumbnail"
const NAMES := ["cover_a_clean.png", "cover_b_title.png", "cover_c_device.png", "cover_d_one_line.png"]


class Cover extends Node2D:
	var kind := 0
	var blast: ImageTexture
	var device: ImageTexture
	var title: Font

	func _init(k: int) -> void:
		kind = k
		blast = ImageTexture.create_from_image(Image.load_from_file(OUT + "/blast_frame_late.png"))
		device = ImageTexture.create_from_image(Image.load_from_file(OUT + "/device_frame.png"))
		title = FontFile.new()
		(title as FontFile).load_dynamic_font(ProjectSettings.globalize_path("res://fonts/lilita_one/LilitaOne-Regular.ttf"))

	func _shade(top: float, bottom: float) -> void:
		for i in 30:
			var a := 1.0 - float(i) / 30.0
			draw_rect(Rect2(0, i * 14, 1080, 14), Color(0.0, 0.0, 0.0, top * a))
			draw_rect(Rect2(0, 1920 - (i + 1) * 14, 1080, 14), Color(0.0, 0.0, 0.0, bottom * a))

	func _line(y: float, text: String, size: int, col: Color) -> void:
		draw_string_outline(title, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 1080, size, 8, Color(0, 0, 0, 0.85))
		draw_string(title, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 1080, size, col)

	func _draw() -> void:
		match kind:
			0:
				draw_texture_rect(blast, Rect2(0, 0, 1080, 1920), false)
				_shade(0.25, 0.2)
			1:
				draw_texture_rect(blast, Rect2(0, 0, 1080, 1920), false)
				_shade(0.55, 0.2)
				_line(250, "INDIA BLEW UP", 92, Color("#ffffff"))
				_line(350, "THE WHITE HOUSE", 92, Color("#ffd45e"))
			2:
				# The device, cropped tighter so the sticker sits high and large.
				draw_texture_rect_region(device, Rect2(0, 0, 1080, 1920), Rect2(110, 180, 840, 1493))
				_shade(0.2, 0.35)
			3:
				draw_texture_rect_region(device, Rect2(0, 0, 1080, 1920), Rect2(110, 180, 840, 1493))
				_shade(0.2, 0.6)
				_line(1700, "CODE NAME: WHITE HOUSE", 76, Color("#ffffff"))


var _i := 0


func _initialize() -> void:
	_show()


func _show() -> void:
	for c in root.get_children():
		c.queue_free()
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	root.size = Vector2i(1080, 1920)
	root.content_scale_size = Vector2i(1080, 1920)
	root.add_child(Cover.new(_i))
	call_deferred("_capture")


func _capture() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(OUT + "/" + NAMES[_i])
	print("Saved: ", NAMES[_i])
	_i += 1
	if _i < NAMES.size():
		_show()
	else:
		quit()
