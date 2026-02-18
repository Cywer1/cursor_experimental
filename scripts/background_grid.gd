extends ParallaxBackground

const GRID_SIZE := 128
const BORDER_COLOR := Color("#2a2a35")

func _ready() -> void:
	var parallax_layer := get_node_or_null("ParallaxLayer") as ParallaxLayer
	if parallax_layer == null:
		return
	var grid_pattern := parallax_layer.get_node_or_null("GridPattern") as TextureRect
	if grid_pattern == null:
		return
	var img := Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in GRID_SIZE:
		img.set_pixel(x, 0, BORDER_COLOR)
		img.set_pixel(x, GRID_SIZE - 1, BORDER_COLOR)
	for y in GRID_SIZE:
		img.set_pixel(0, y, BORDER_COLOR)
		img.set_pixel(GRID_SIZE - 1, y, BORDER_COLOR)
	var tex := ImageTexture.create_from_image(img)
	grid_pattern.texture = tex
	grid_pattern.stretch_mode = TextureRect.STRETCH_TILE
