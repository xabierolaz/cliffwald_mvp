class_name Wire

enum Type {
	VARIANT,
	BOOL,
	U8, U16, U32, U64,
	S8, S16, S32, S64,
	F16, F32, F64,
	STR_UTF8_U16, STR_UTF8_U32,
	STR_ASCII_U16, STR_ASCII_U32,
	BYTES_U16, BYTES_U32,
	VEC2_F32,
	VEC3_F32, # Nuevo para 3D
	QUAT_F32  # Nuevo para Rotaciones
}
