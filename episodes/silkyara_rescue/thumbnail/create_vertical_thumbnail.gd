extends SceneTree
## Compose a vertical Short cover using the episode's rendered frames.

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/silkyara_rescue/thumbnail"

class Cover extends Node2D:
	var rescue := ImageTexture.create_from_image(Image.load_from_file(OUT + "/rescue_frame.png"))
	var hasan := ImageTexture.create_from_image(Image.load_from_file(OUT + "/hasan_frame.png"))
	var title: Font = load("res://fonts/lilita_one/LilitaOne-Regular.ttf")
	var body: Font = load("res://fonts/baloo2/Baloo2.ttf")

	func _draw() -> void:
		draw_texture_rect_region(rescue, Rect2(0, 0, 1080, 960), Rect2(0, 240, 1080, 960))
		draw_texture_rect_region(hasan, Rect2(0, 970, 1080, 950), Rect2(0, 650, 1080, 950))
		draw_rect(Rect2(0, 0, 1080, 110), Color(0.025, 0.03, 0.04, 0.86))
		draw_string(body, Vector2(30, 75), "THE SILKYARA RESCUE", HORIZONTAL_ALIGNMENT_CENTER, 1020, 54, Color("#fff9e8"))
		draw_rect(Rect2(0, 954, 1080, 16), Color("#f4bc42"))
		draw_rect(Rect2(0, 1480, 1080, 440), Color(0.02, 0.025, 0.035, 0.82))
		draw_string_outline(title, Vector2(20, 1615), "HELPED SAVE 41", HORIZONTAL_ALIGNMENT_CENTER, 1040, 103, 12, Color("#111319"))
		draw_string(title, Vector2(20, 1615), "HELPED SAVE 41", HORIZONTAL_ALIGNMENT_CENTER, 1040, 103, Color("#fffdf4"))
		draw_string_outline(title, Vector2(20, 1740), "THEN LOST", HORIZONTAL_ALIGNMENT_CENTER, 1040, 112, 12, Color("#111319"))
		draw_string(title, Vector2(20, 1740), "THEN LOST", HORIZONTAL_ALIGNMENT_CENTER, 1040, 112, Color("#ffd45e"))
		draw_string_outline(title, Vector2(20, 1860), "HIS HOME", HORIZONTAL_ALIGNMENT_CENTER, 1040, 112, 12, Color("#111319"))
		draw_string(title, Vector2(20, 1860), "HIS HOME", HORIZONTAL_ALIGNMENT_CENTER, 1040, 112, Color("#ffd45e"))

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	root.size = Vector2i(1080, 1920)
	root.content_scale_size = Vector2i(1080, 1920)
	root.add_child(Cover.new())
	call_deferred("_capture")

func _capture() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT + "/silkyara_shorts_cover.png")
	if error != OK:
		printerr("Failed to save Short cover: ", error)
		quit(1)
		return
	print("Short cover saved: ", OUT + "/silkyara_shorts_cover.png")
	quit()
