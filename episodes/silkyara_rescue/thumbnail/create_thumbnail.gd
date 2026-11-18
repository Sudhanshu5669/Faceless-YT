extends SceneTree
## Compose a YouTube thumbnail from frames rendered by TownForge. No generated imagery.

const OUT := "E:/Sudhanshu/Projects/Town-forge/episodes/silkyara_rescue/thumbnail"

class Thumbnail extends Node2D:
	var rescue: ImageTexture
	var hasan: ImageTexture
	var title: Font
	var body: Font

	func _init() -> void:
		rescue = ImageTexture.create_from_image(Image.load_from_file(OUT + "/rescue_frame.png"))
		hasan = ImageTexture.create_from_image(Image.load_from_file(OUT + "/hasan_frame.png"))
		title = load("res://fonts/lilita_one/LilitaOne-Regular.ttf")
		body = load("res://fonts/baloo2/Baloo2.ttf")

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("#121418"))
		# Two unaltered episode stills, cropped to fill the landscape frame.
		draw_texture_rect_region(rescue, Rect2(0, 0, 636, 720), Rect2(0, 260, 1080, 1222))
		draw_texture_rect_region(hasan, Rect2(644, 0, 636, 720), Rect2(0, 365, 1080, 1222))
		# Restrained grading and a bottom scrim keep the text readable at phone size.
		draw_rect(Rect2(0, 0, 636, 720), Color(0.16, 0.07, 0.01, 0.10))
		draw_rect(Rect2(644, 0, 636, 720), Color(0.06, 0.08, 0.13, 0.12))
		for i in 24:
			var alpha := 0.78 * float(i + 1) / 24.0
			draw_rect(Rect2(0, 400 + i * 13, 1280, 14), Color(0.025, 0.03, 0.04, alpha))
		draw_rect(Rect2(0, 0, 1280, 62), Color(0.025, 0.03, 0.04, 0.86))
		draw_rect(Rect2(628, 0, 16, 490), Color("#f4bc42"))
		draw_string(body, Vector2(32, 41), "THE SILKYARA RESCUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f8f1dc"))
		draw_string(body, Vector2(925, 41), "2023  /  2024", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#d9d5cb"))
		# Heavy outline makes the promise legible on the small YouTube preview.
		draw_string_outline(title, Vector2(24, 548), "HELPED SAVE 41", HORIZONTAL_ALIGNMENT_CENTER, 1232, 91, 11, Color("#111319"))
		draw_string(title, Vector2(24, 548), "HELPED SAVE 41", HORIZONTAL_ALIGNMENT_CENTER, 1232, 91, Color("#fffdf4"))
		draw_string_outline(title, Vector2(24, 652), "THEN LOST HIS HOME", HORIZONTAL_ALIGNMENT_CENTER, 1232, 91, 11, Color("#111319"))
		draw_string(title, Vector2(24, 652), "THEN LOST HIS HOME", HORIZONTAL_ALIGNMENT_CENTER, 1232, 91, Color("#ffd45e"))


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.add_child(Thumbnail.new())
	call_deferred("_capture")


func _capture() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	var error := result.save_png(OUT + "/silkyara_youtube_thumbnail.png")
	if error != OK:
		printerr("Failed to save thumbnail: ", error)
		quit(1)
		return
	print("Thumbnail saved: ", OUT + "/silkyara_youtube_thumbnail.png")
	quit()
