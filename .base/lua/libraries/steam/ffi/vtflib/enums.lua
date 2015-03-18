return {
	VTFLIB_DXT_QUALITY = 0,
	VTFLIB_LUMINANCE_WEIGHT_R = 1,
	VTFLIB_LUMINANCE_WEIGHT_G = 2,
	VTFLIB_LUMINANCE_WEIGHT_B = 3,
	VTFLIB_BLUESCREEN_MASK_R = 4,
	VTFLIB_BLUESCREEN_MASK_G = 5,
	VTFLIB_BLUESCREEN_MASK_B = 6,
	VTFLIB_BLUESCREEN_CLEAR_R = 7,
	VTFLIB_BLUESCREEN_CLEAR_G = 8,
	VTFLIB_BLUESCREEN_CLEAR_B = 9,
	VTFLIB_FP16_HDR_KEY = 10,
	VTFLIB_FP16_HDR_SHIFT = 11,
	VTFLIB_FP16_HDR_GAMMA = 12,
	VTFLIB_UNSHARPEN_RADIUS = 13,
	VTFLIB_UNSHARPEN_AMOUNT = 14,
	VTFLIB_UNSHARPEN_THRESHOLD = 15,
	VTFLIB_XSHARPEN_STRENGTH = 16,
	VTFLIB_XSHARPEN_THRESHOLD = 17,
	VTFLIB_VMT_PARSE_MODE = 18,
	IMAGE_FORMAT_RGBA8888 = 0,
	IMAGE_FORMAT_ABGR8888 = 1,
	IMAGE_FORMAT_RGB888 = 2,
	IMAGE_FORMAT_BGR888 = 3,
	IMAGE_FORMAT_RGB565 = 4,
	IMAGE_FORMAT_I8 = 5,
	IMAGE_FORMAT_IA88 = 6,
	IMAGE_FORMAT_P8 = 7,
	IMAGE_FORMAT_A8 = 8,
	IMAGE_FORMAT_RGB888_BLUESCREEN = 9,
	IMAGE_FORMAT_BGR888_BLUESCREEN = 10,
	IMAGE_FORMAT_ARGB8888 = 11,
	IMAGE_FORMAT_BGRA8888 = 12,
	IMAGE_FORMAT_DXT1 = 13,
	IMAGE_FORMAT_DXT3 = 14,
	IMAGE_FORMAT_DXT5 = 15,
	IMAGE_FORMAT_BGRX8888 = 16,
	IMAGE_FORMAT_BGR565 = 17,
	IMAGE_FORMAT_BGRX5551 = 18,
	IMAGE_FORMAT_BGRA4444 = 19,
	IMAGE_FORMAT_DXT1_ONEBITALPHA = 20,
	IMAGE_FORMAT_BGRA5551 = 21,
	IMAGE_FORMAT_UV88 = 22,
	IMAGE_FORMAT_UVWQ8888 = 23,
	IMAGE_FORMAT_RGBA16161616F = 24,
	IMAGE_FORMAT_RGBA16161616 = 25,
	IMAGE_FORMAT_UVLX8888 = 26,
	IMAGE_FORMAT_R32F = 27,
	IMAGE_FORMAT_RGB323232F = 28,
	IMAGE_FORMAT_RGBA32323232F = 29,
	IMAGE_FORMAT_NV_DST16 = 30,
	IMAGE_FORMAT_NV_DST24 = 31,
	IMAGE_FORMAT_NV_INTZ = 32,
	IMAGE_FORMAT_NV_RAWZ = 33,
	IMAGE_FORMAT_ATI_DST16 = 34,
	IMAGE_FORMAT_ATI_DST24 = 35,
	IMAGE_FORMAT_NV_NULL = 36,
	IMAGE_FORMAT_ATI2N = 37,
	IMAGE_FORMAT_ATI1N = 38,
	IMAGE_FORMAT_COUNT = 39,
	IMAGE_FORMAT_NONE = 40,
	TEXTUREFLAGS_POINTSAMPLE = 0x00000001,
	TEXTUREFLAGS_TRILINEAR = 0x00000002,
	TEXTUREFLAGS_CLAMPS = 0x00000004,
	TEXTUREFLAGS_CLAMPT = 0x00000008,
	TEXTUREFLAGS_ANISOTROPIC = 0x00000010,
	TEXTUREFLAGS_HINT_DXT5 = 0x00000020,
	TEXTUREFLAGS_SRGB = 0x00000040,
	TEXTUREFLAGS_DEPRECATED_NOCOMPRESS = 0x00000040,
	TEXTUREFLAGS_NORMAL = 0x00000080,
	TEXTUREFLAGS_NOMIP = 0x00000100,
	TEXTUREFLAGS_NOLOD = 0x00000200,
	TEXTUREFLAGS_MINMIP = 0x00000400,
	TEXTUREFLAGS_PROCEDURAL = 0x00000800,
	TEXTUREFLAGS_ONEBITALPHA = 0x00001000,
	TEXTUREFLAGS_EIGHTBITALPHA = 0x00002000,
	TEXTUREFLAGS_ENVMAP = 0x00004000,
	TEXTUREFLAGS_RENDERTARGET = 0x00008000,
	TEXTUREFLAGS_DEPTHRENDERTARGET = 0x00010000,
	TEXTUREFLAGS_NODEBUGOVERRIDE = 0x00020000,
	TEXTUREFLAGS_SINGLECOPY = 0x00040000,
	TEXTUREFLAGS_UNUSED0 = 0x00080000,
	TEXTUREFLAGS_DEPRECATED_ONEOVERMIPLEVELINALPHA = 0x00080000,
	TEXTUREFLAGS_UNUSED1 = 0x00100000,
	TEXTUREFLAGS_DEPRECATED_PREMULTCOLORBYONEOVERMIPLEVEL = 0x00100000,
	TEXTUREFLAGS_UNUSED2 = 0x00200000,
	TEXTUREFLAGS_DEPRECATED_NORMALTODUDV = 0x00200000,
	TEXTUREFLAGS_UNUSED3 = 0x00400000,
	TEXTUREFLAGS_DEPRECATED_ALPHATESTMIPGENERATION = 0x00400000,
	TEXTUREFLAGS_NODEPTHBUFFER = 0x00800000,
	TEXTUREFLAGS_UNUSED4 = 0x01000000,
	TEXTUREFLAGS_DEPRECATED_NICEFILTERED = 0x01000000,
	TEXTUREFLAGS_CLAMPU = 0x02000000,
	TEXTUREFLAGS_VERTEXTEXTURE = 0x04000000,
	TEXTUREFLAGS_SSBUMP = 0x08000000,
	TEXTUREFLAGS_UNUSED5 = 0x10000000,
	TEXTUREFLAGS_DEPRECATED_UNFILTERABLE_OK = 0x10000000,
	TEXTUREFLAGS_BORDER = 0x20000000,
	TEXTUREFLAGS_DEPRECATED_SPECVAR_RED = 0x40000000,
	TEXTUREFLAGS_DEPRECATED_SPECVAR_ALPHA = 0x80000000,
	TEXTUREFLAGS_LAST = 0x20000000,
	TEXTUREFLAGS_COUNT = 536870913,
	CUBEMAP_FACE_RIGHT = 0,
	CUBEMAP_FACE_LEFT = 1,
	CUBEMAP_FACE_BACK = 2,
	CUBEMAP_FACE_FRONT = 3,
	CUBEMAP_FACE_UP = 4,
	CUBEMAP_FACE_DOWN = 5,
	CUBEMAP_FACE_SPHERE_MAP = 6,
	CUBEMAP_FACE_COUNT = 7,
	MIPMAP_FILTER_POINT = 0,
	MIPMAP_FILTER_BOX = 1,
	MIPMAP_FILTER_TRIANGLE = 2,
	MIPMAP_FILTER_QUADRATIC = 3,
	MIPMAP_FILTER_CUBIC = 4,
	MIPMAP_FILTER_CATROM = 5,
	MIPMAP_FILTER_MITCHELL = 6,
	MIPMAP_FILTER_GAUSSIAN = 7,
	MIPMAP_FILTER_SINC = 8,
	MIPMAP_FILTER_BESSEL = 9,
	MIPMAP_FILTER_HANNING = 10,
	MIPMAP_FILTER_HAMMING = 11,
	MIPMAP_FILTER_BLACKMAN = 12,
	MIPMAP_FILTER_KAISER = 13,
	MIPMAP_FILTER_COUNT = 14,
	SHARPEN_FILTER_NONE = 0,
	SHARPEN_FILTER_NEGATIVE = 1,
	SHARPEN_FILTER_LIGHTER = 2,
	SHARPEN_FILTER_DARKER = 3,
	SHARPEN_FILTER_CONTRASTMORE = 4,
	SHARPEN_FILTER_CONTRASTLESS = 5,
	SHARPEN_FILTER_SMOOTHEN = 6,
	SHARPEN_FILTER_SHARPENSOFT = 7,
	SHARPEN_FILTER_SHARPENMEDIUM = 8,
	SHARPEN_FILTER_SHARPENSTRONG = 9,
	SHARPEN_FILTER_FINDEDGES = 10,
	SHARPEN_FILTER_CONTOUR = 11,
	SHARPEN_FILTER_EDGEDETECT = 12,
	SHARPEN_FILTER_EDGEDETECTSOFT = 13,
	SHARPEN_FILTER_EMBOSS = 14,
	SHARPEN_FILTER_MEANREMOVAL = 15,
	SHARPEN_FILTER_UNSHARP = 16,
	SHARPEN_FILTER_XSHARPEN = 17,
	SHARPEN_FILTER_WARPSHARP = 18,
	SHARPEN_FILTER_COUNT = 19,
	DXT_QUALITY_LOW = 0,
	DXT_QUALITY_MEDIUM = 1,
	DXT_QUALITY_HIGH = 2,
	DXT_QUALITY_HIGHEST = 3,
	DXT_QUALITY_COUNT = 4,
	KERNEL_FILTER_4X = 0,
	KERNEL_FILTER_3X3 = 1,
	KERNEL_FILTER_5X5 = 2,
	KERNEL_FILTER_7X7 = 3,
	KERNEL_FILTER_9X9 = 4,
	KERNEL_FILTER_DUDV = 5,
	KERNEL_FILTER_COUNT = 6,
	HEIGHT_CONVERSION_METHOD_ALPHA = 0,
	HEIGHT_CONVERSION_METHOD_AVERAGE_RGB = 1,
	HEIGHT_CONVERSION_METHOD_BIASED_RGB = 2,
	HEIGHT_CONVERSION_METHOD_RED = 3,
	HEIGHT_CONVERSION_METHOD_GREEN = 4,
	HEIGHT_CONVERSION_METHOD_BLUE = 5,
	HEIGHT_CONVERSION_METHOD_MAX_RGB = 6,
	HEIGHT_CONVERSION_METHOD_COLORSPACE = 7,
	HEIGHT_CONVERSION_METHOD_COUNT = 8,
	NORMAL_ALPHA_RESULT_NOCHANGE = 0,
	NORMAL_ALPHA_RESULT_HEIGHT = 1,
	NORMAL_ALPHA_RESULT_BLACK = 2,
	NORMAL_ALPHA_RESULT_WHITE = 3,
	NORMAL_ALPHA_RESULT_COUNT = 4,
	RESIZE_NEAREST_POWER2 = 0,
	RESIZE_BIGGEST_POWER2 = 1,
	RESIZE_SMALLEST_POWER2 = 2,
	RESIZE_SET = 3, 
	RESIZE_COUNT = 4,
	RSRCF_HAS_NO_DATA_CHUNK = 5,
	 VTF_LEGACY_RSRC_LOW_RES_IMAGE = 1,
	VTF_LEGACY_RSRC_IMAGE = 48,
	VTF_RSRC_SHEET = 16,
	VTF_RSRC_CRC = 37966403,
	VTF_RSRC_TEXTURE_LOD_SETTINGS = 38031180,
	VTF_RSRC_TEXTURE_SETTINGS_EX = 38753108,
	VTF_RSRC_KEY_VALUE_DATA = 4478539,
	VTF_RSRC_MAX_DICTIONARY_ENTRIES = 32,
	PARSE_MODE_STRICT = 0,
	PARSE_MODE_LOOSE = 1,
	PARSE_MODE_COUNT = 2,
	NODE_TYPE_GROUP = 0,
	NODE_TYPE_GROUP_END = 1,
	NODE_TYPE_STRING = 2,
	NODE_TYPE_INTEGER = 3,
	NODE_TYPE_SINGLE = 4,
	NODE_TYPE_COUNT = 5,
}