#include "libpng16/png.h"

#include "lua.hpp"

#include <memory>
#include <random>
#include <vector>

// for _rdrand32_step
#include <immintrin.h>

class LuaAutoStack
{
public:
	LuaAutoStack(lua_State *L) : L(L), index(lua_gettop(L)) {}
	~LuaAutoStack()
	{
		lua_settop(L, index);
	}

private:
	lua_State *L;
	int index;
};

template<typename T>
T* LuaNew(lua_State *L)
{
	void *ud = lua_newuserdata(L, sizeof(T));
	return new (ud) T();
}

template<typename T>
int LuaDelete(lua_State *L)
{
	T *p = (T*)luaL_checkudata(L, 1, T::kClassName);
	if(p)
		p->~T();
	return 0;
}

template<typename T, int (T::*fn)(lua_State*)>
int LuaForward(lua_State *L)
{
	T *p = (T*)luaL_checkudata(L, 1, T::kClassName);
	return (p->*fn)(L);
}

void SetFn(lua_State *L, const char *name, lua_CFunction cf)
{
	lua_pushcfunction(L, cf);
	lua_setfield(L, -2, name);
}

uint32_t DoBlit(uint32_t src, uint32_t dst)
{
	uint32_t srca = src >> 24;
	if(srca == 0)
		return dst;
	if(srca == 255)
		return src;
	return src;
}

class LuaImagePNG
{
public:
	LuaImagePNG()
	{
	}
	~LuaImagePNG()
	{
	}

	static constexpr char kClassName[] = "LuaImagePNG";

	static void Register(lua_State *L)
	{
		lua_pushcfunction(L, LuaLoadImage);
		lua_setglobal(L, "LoadImage");
		lua_pushcfunction(L, LuaCreateEmptyImage);
		lua_setglobal(L, "CreateEmptyImage");

		luaL_newmetatable(L, kClassName);
		lua_newtable(L);

		SetFn(L, "width", LuaForward<LuaImagePNG, &LuaImagePNG::width>);
		SetFn(L, "height", LuaForward<LuaImagePNG, &LuaImagePNG::height>);
		SetFn(L, "Load", LuaForward<LuaImagePNG, &LuaImagePNG::LuaLoad>);
		SetFn(L, "Save", LuaForward<LuaImagePNG, &LuaImagePNG::LuaSave>);
		SetFn(L, "Blit", LuaForward<LuaImagePNG, &LuaImagePNG::LuaBlit>);
		SetFn(L, "BlitEmpty", LuaForward<LuaImagePNG, &LuaImagePNG::LuaBlitEmpty>);
		SetFn(L, "CopyFrom", LuaForward<LuaImagePNG, &LuaImagePNG::LuaCopyFrom>);

		lua_setfield(L, -2, "__index");
		SetFn(L, "__gc", LuaDelete<LuaImagePNG>);
		lua_pop(L, 1);
	}

	int width(lua_State *L) { lua_pushinteger(L, w_); return 1; }
	int height(lua_State *L) { lua_pushinteger(L, h_); return 1; }
	int LuaLoad(lua_State *L);
	int LuaSave(lua_State *L);
	int LuaBlit(lua_State *L);
	int LuaBlitEmpty(lua_State *L);
	int LuaCopyFrom(lua_State *L);

	static int LuaLoadImage(lua_State *L);
	static int LuaCreateEmptyImage(lua_State *L);

	uint32_t w_ = 0, h_ = 0;
	std::unique_ptr<uint32_t[]> pixels;
};

void png_read(png_structp png, png_bytep data, size_t n)
{
	FILE *f = (FILE*)png_get_io_ptr(png);
	fread(data, n, 1, f);
}

void png_write(png_structp png, png_bytep data, size_t n)
{
	FILE *f = (FILE*)png_get_io_ptr(png);
	fwrite(data, n, 1, f);
}

void png_flush(png_structp png) {}

int LuaImagePNG::LuaLoad(lua_State *L)
{
	const char *f = luaL_checkstring(L, 2);
	FILE *fp = fopen(f, "rb");
	if(!fp)
		return 0;
	auto png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	auto png_info = png_create_info_struct(png);
	if(!png_info) {
		png_destroy_read_struct(&png, NULL, NULL);
		return 0;
	}
	png_set_read_fn(png, fp, png_read);
	png_read_info(png, png_info);
	int bpp, type;
	if(png_get_IHDR(png, png_info, &w_, &h_, &bpp, &type, nullptr, nullptr, nullptr) != 1) {
		png_destroy_read_struct(&png, &png_info, NULL);
		return 0;
	}
	if (bpp == 16)
		png_set_strip_16(png);
	if (bpp == 8 && type == PNG_COLOR_TYPE_RGB)
		png_set_filler(png,	255, PNG_FILLER_AFTER);
	pixels.reset(new uint32_t[w_ * h_]);
	std::vector<png_bytep> rows;
	for(int i = 0; i < h_; i++)
		rows.push_back((png_bytep)&pixels[i * w_]);
	png_read_image(png, rows.data());

	png_bytep trans;
	int ntrans;
	png_color_16p transcolors;
	if(png_get_tRNS(png, png_info, &trans, &ntrans, &transcolors) == PNG_INFO_tRNS) {
		uint32_t c = transcolors[0].red & 0xFF;
		c |= (transcolors[0].green & 0xFF) << 8;
		c |= (transcolors[0].blue & 0xFF) << 16;
		for(int y = 0; y < h_; y++) {
			for(int x = 0; x < w_; x++) {
				if((pixels[y * w_ + x] & 0xFFFFFF) == c)
					pixels[y * w_ + x] = 0;
			}
		}
	}

	png_destroy_read_struct(&png, &png_info, NULL);
	fclose(fp);

	lua_pushboolean(L, 1);
	return 1;
}

int LuaImagePNG::LuaSave(lua_State *L)
{
	const char *f = luaL_checkstring(L, 2);

	FILE *fp = fopen(f, "wb");
	if (!fp)
		return 0;

	png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
	if (!png)
		return 0;

	png_infop png_info = png_create_info_struct(png);
	if (!png_info) {
		png_destroy_write_struct(&png, nullptr);
		return 0;
	}
	png_set_write_fn(png, fp, png_write, png_flush);
	png_set_compression_level(png, 9);

	/* set other zlib parameters */
	png_set_compression_mem_level(png, 8);
	png_set_compression_strategy(png, 0);
	png_set_compression_window_bits(png, 15);
	png_set_compression_method(png, 8);

	std::vector<png_bytep> rows;
	for(int i = 0; i < h_; i++)
		rows.push_back((png_bytep)&pixels[i * w_]);

	png_set_IHDR(png, png_info, w_, h_, 8, PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
	png_write_info(png, png_info);
	png_write_image(png, rows.data());
	png_write_end(png, png_info);
	fclose(fp);

	png_destroy_write_struct(&png, &png_info);

	lua_pushboolean(L, 1);
	return 1;
}

int LuaImagePNG::LuaCopyFrom(lua_State *L)
{
	void *ptr = lua_touserdata(L, 2);
	int t = lua_type(L, 2);
	LuaImagePNG *src = (LuaImagePNG*)luaL_checkudata(L, 2, kClassName);
	if(!src)
		return luaL_error(L, "copyfrom requires a source image");
	w_ = src->w_;
	h_ = src->h_;
	pixels.reset(new uint32_t[w_ * h_]);
	memcpy(pixels.get(), src->pixels.get(), w_ * h_ * 4);
	lua_pushboolean(L, 1);
	return 1;
}

int LuaImagePNG::LuaBlitEmpty(lua_State *L)
{
	int x0 = lua_tointeger(L, 2);
	int y0 = lua_tointeger(L, 3);
	int w = lua_tointeger(L, 4);
	int h = lua_tointeger(L, 5);
	if(w <= 0) w = w_;
	if(h <= 0) h = h_;

	for(int y = 0; y < h; y++) {
		for(int x = 0; x < w; x++) {
			if(x + x0 >= w_ || y + y0 >= h_)
				continue;
			pixels[(y + y0) * w_ + x + x0] = 0;
		}
	}

	return 0;
}

int LuaImagePNG::LuaBlit(lua_State *L)
{
	LuaImagePNG *src = (LuaImagePNG*)lua_touserdata(L, 2);
	if(!src)
		return luaL_error(L, "blit requires a source image");
	int dx, dy, sx, sy, w, h;
	int n = lua_gettop(L);
	if(n < 4) {
		luaL_error(L, "expected at least 4 arguments");
		return 0;
	}
	int idx = 3;
	if(lua_istable(L, idx)) {
		LuaAutoStack stk(L);
		lua_getfield(L, idx, "x0");
		dx = lua_tointeger(L, -1);
		lua_getfield(L, idx, "y0");
		dy = lua_tointeger(L, -1);
		idx++;
	} else {
		dx = luaL_checkinteger(L, idx++);
		dy = luaL_checkinteger(L, idx++);
	}
	if(lua_istable(L, idx)) {
		LuaAutoStack stk(L);
		lua_getfield(L, idx, "x0");
		sx = lua_tointeger(L, -1);
		lua_getfield(L, idx, "y0");
		sy = lua_tointeger(L, -1);
		idx++;
	} else {
		sx = luaL_checkinteger(L, idx++);
		sy = luaL_checkinteger(L, idx++);
	}
	if(lua_istable(L, idx)) {
		LuaAutoStack stk(L);
		lua_getfield(L, idx, "w");
		if(lua_isnil(L, -1)) {
			const char *s = lua_tostring(L, -1);
			if(!strcmp(s, "*"))
				w = w_ - dx;
			else
				w = lua_tointeger(L, -1);
		} else {
			lua_getfield(L, idx, "x0");
			lua_getfield(L, idx, "x1");
			w = lua_tointeger(L, -1) - lua_tointeger(L, -2);
		}

		lua_getfield(L, idx, "h");
		if(lua_isnil(L, -1)) {
			const char *s = lua_tostring(L, -1);
			if(!strcmp(s, "*"))
				h = h_ - dy;
			else
				h = lua_tointeger(L, -1);
		} else {
			lua_getfield(L, idx, "y0");
			lua_getfield(L, idx, "y1");
			h = lua_tointeger(L, -1) - lua_tointeger(L, -2);
		}

		idx++;
	} else {
		if(lua_isstring(L, idx) && !strcmp(lua_tostring(L, idx), "*")) {
			w = w_ - dx;
			idx++;
		} else {
			w = luaL_checkinteger(L, idx++);
		}
		if(lua_isstring(L, idx) && !strcmp(lua_tostring(L, idx), "*")) {
			h = w_ - dx;
			idx++;
		} else {
			h = luaL_checkinteger(L, idx++);
		}
	}

	const uint32_t *src_base = &src->pixels[sx + sy * src->w_];
	uint32_t *dst_base = &pixels[dx + dy * w_];

	for(int y = 0; y < h; y++) {
		for(int x = 0; x < w; x++) {
			if(x + dx >= w_ || x + sx >= src->w_ || y + dy >= h_ || y + sy >= src->h_)
				continue;
			uint32_t s = src_base[x + y * src->w_];
			uint32_t *d = &dst_base[y * w_ + x];
			*d = DoBlit(s, *d);
		}
	}

	return 0;
}


int LuaImagePNG::LuaLoadImage(lua_State *L)
{
	lua_pushvalue(L, 1);
	LuaImagePNG *img = LuaNew<LuaImagePNG>(L);
	if(!img->LuaLoad(L)) {
		return 0;
	}

	lua_pop(L, 1);

	luaL_getmetatable(L, kClassName);
	lua_setmetatable(L, -2);
	return 1;
}
int LuaImagePNG::LuaCreateEmptyImage(lua_State *L)
{
	LuaImagePNG *img = LuaNew<LuaImagePNG>(L);
	luaL_getmetatable(L, kClassName);
	lua_setmetatable(L, -2);
	return 1;
}

static std::mt19937 _rng;
static uint32_t rng_count = 0;
static std::uniform_real_distribution<double> rng_01;

int lua_rng(lua_State *L)
{
	lua_Number r = rng_01(_rng);
	printf("Raw rand: %f\n", r);
	rng_count++;
	lua_pushinteger(L, rng_count);
	lua_setglobal(L, "rng_count");
	switch (lua_gettop(L)) {  /* check number of arguments */
		case 0: {  /* no arguments */
			lua_pushnumber(L, r);  /* Number between 0 and 1 */
		break;
		}
		case 1: {  /* only upper limit */
			int u = luaL_checkinteger(L, 1);
			luaL_argcheck(L, 1<=u, 1, "interval is empty");
			lua_pushnumber(L, floor(r*u)+1);  /* int between 1 and `u' */
			break;
		}
		case 2: {  /* lower and upper limits */
			int l = luaL_checkinteger(L, 1);
			int u = luaL_checkinteger(L, 2);
			luaL_argcheck(L, l<=u, 2, "interval is empty");
			lua_pushnumber(L, floor(r*(u-l+1))+l);  /* int between `l' and `u' */
		break;
		}
		default: return luaL_error(L, "wrong number of arguments");
	}
	return 1;
}

int lua_rngseed(lua_State *L) {
	size_t n;
	const char *p = lua_tolstring(L, 1, &n);
	if(!p || n < 24) {
		luaL_error(L, "seed error: too short (%d)", n);
	}
	uint32_t seed[6];
	memcpy(seed, p, 24);
	std::seed_seq seq;
	seq.generate(seed, seed + 6);
	_rng.seed(seq);
	rng_count = 0;
	n = lua_tointeger(L, 2);
	lua_pushinteger(L, n);
	lua_setglobal(L, "rng_count");
	_rng.discard(n + 10000);
	rng_count = n;
	return 0;
}

static void rng_init(lua_State *L)
{
	uint32_t key[6];
	for(int i = 0; i < 6; i++)
		while(!_rdrand32_step(&key[i]));
	std::seed_seq seq;
	seq.generate(key, key + 6);
	_rng.seed(seq);
	rng_count = 0;

	_rng.discard(10000);


	lua_pushcfunction(L, lua_rng);
	lua_setglobal(L, "mersenne_twister");
	lua_pushcfunction(L, lua_rngseed);
	lua_setglobal(L, "mersenne_twister_seedfunc");
	lua_pushlstring(L, (const char*)key, sizeof(key));
	lua_setglobal(L, "mersenne_twister_seed");
}

static int traceback (lua_State *L) {
  if (!lua_isstring(L, 1))  /* 'message' not a string? */
    return 1;  /* keep it intact */
  lua_getglobal(L, "debug");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);
    return 1;
  }
  lua_pushvalue(L, 1);  /* pass error message */
  lua_pushinteger(L, 2);  /* skip this function and traceback */
  lua_call(L, 2, 1);  /* call debug.traceback */
  return 1;
}

int main(int argc, char **argv)
{
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	LuaImagePNG::Register(L);
	rng_init(L);
	if(luaL_loadfile(L, "bsg_app.lua")) {
		printf("load error: %s\n", lua_tostring(L, -1));
		return 1;
	}
	lua_pushboolean(L, 1);
	lua_setglobal(L, "running_embedded");
	if(lua_pcall(L, 0, 0, 0)) {
		printf("exec error: %s\n", lua_tostring(L, -1));
		return 1;
	}

	lua_pushcfunction(L, traceback);
	lua_getglobal(L, "main");
	if(!lua_isfunction(L, -1)) {
		printf("No such global function main()");
		return 1;
	}
	lua_newtable(L);
	for(int i = 1; i < argc; i++) {
		lua_pushstring(L, argv[i]);
		lua_rawseti(L, -2, i);
	}
	if(lua_pcall(L, 1, 0, -3)) {
		printf("exec error: %s\n", lua_tostring(L, -1));
		return 1;
	}
	return 0;
}
