extends RefCounted
## Loading source images. The format is detected from the file's bytes, not its
## extension, so .jfif and mislabelled files still load. Images come back as RGBA8.

const PNG_MAGIC := [0x89, 0x50, 0x4E, 0x47]
const JPG_MAGIC := [0xFF, 0xD8, 0xFF]
const RIFF_MAGIC := [0x52, 0x49, 0x46, 0x46]
const BMP_MAGIC := [0x42, 0x4D]


## Returns null if the file can't be read or isn't a supported image.
static func load_image(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var image := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if _starts_with(bytes, PNG_MAGIC):
		err = image.load_png_from_buffer(bytes)
	elif _starts_with(bytes, JPG_MAGIC):
		err = image.load_jpg_from_buffer(bytes)
	elif _starts_with(bytes, RIFF_MAGIC) and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		err = image.load_webp_from_buffer(bytes)
	elif _starts_with(bytes, BMP_MAGIC):
		err = image.load_bmp_from_buffer(bytes)
	if err != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


static func _starts_with(bytes: PackedByteArray, magic: Array) -> bool:
	if bytes.size() < magic.size():
		return false
	for i in magic.size():
		if bytes[i] != magic[i]:
			return false
	return true
