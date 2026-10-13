// LD_PRELOAD shim v2: times every GL draw call and reports the slow ones (a driver building a
// pipeline for a kind of draw it has not seen) with the state they were made in, by frame.
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

typedef void (*anyfn)(void);
typedef unsigned int GLenum; typedef unsigned int GLuint; typedef int GLint; typedef int GLsizei;
typedef unsigned char GLboolean; typedef long GLintptr;
static void *(*real_dlsym)(void *, const char *);
static anyfn (*real_gpa)(const unsigned char *);
static anyfn (*real_gpa_arb)(const unsigned char *);
static FILE *out; static long frame = 0; static double slow_ms = 15.0;
static double now_ms(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec * 1000.0 + t.tv_nsec / 1e6; }
static void init_out(void) { if (!out) { const char *p = getenv("GLSHIM_LOG"); out = p ? fopen(p, "w") : stderr; const char *s = getenv("GLSHIM_SLOW"); if (s) slow_ms = atof(s); } }

// ---- tracked state
static GLuint cur_prog, cur_vao, cur_fbo, cur_unit;
static int blend_on, scissor_on; static GLenum bs_rgb = 1, bd_rgb = 0, bs_a = 1, bd_a = 0, beq = 0x8006;
#define NV 8192
static struct { unsigned mask; unsigned sig[16]; unsigned div[16]; } vao[NV];
#define NT 16384
static struct { int w, h; GLenum fmt; } tex[NT];
static GLuint unit_tex[32];
static int links_this_frame; static double link_ms;

static void (*r_UseProgram)(GLuint); static void my_UseProgram(GLuint p) { cur_prog = p; r_UseProgram(p); }
static void (*r_Enable)(GLenum); static void my_Enable(GLenum c) { if (c == 0x0BE2) blend_on = 1; if (c == 0x0C11) scissor_on = 1; r_Enable(c); }
static void (*r_Disable)(GLenum); static void my_Disable(GLenum c) { if (c == 0x0BE2) blend_on = 0; if (c == 0x0C11) scissor_on = 0; r_Disable(c); }
static void (*r_BlendFunc)(GLenum, GLenum); static void my_BlendFunc(GLenum s, GLenum d) { bs_rgb = bs_a = s; bd_rgb = bd_a = d; r_BlendFunc(s, d); }
static void (*r_BlendFuncSeparate)(GLenum, GLenum, GLenum, GLenum); static void my_BlendFuncSeparate(GLenum a, GLenum b, GLenum c, GLenum d) { bs_rgb = a; bd_rgb = b; bs_a = c; bd_a = d; r_BlendFuncSeparate(a, b, c, d); }
static void (*r_BlendEquation)(GLenum); static void my_BlendEquation(GLenum e) { beq = e; r_BlendEquation(e); }
static void (*r_BindVertexArray)(GLuint); static void my_BindVertexArray(GLuint v) { cur_vao = v; r_BindVertexArray(v); }
static void (*r_EnableVAA)(GLuint); static void my_EnableVAA(GLuint i) { if (i < 16) vao[cur_vao % NV].mask |= 1u << i; r_EnableVAA(i); }
static void (*r_DisableVAA)(GLuint); static void my_DisableVAA(GLuint i) { if (i < 16) vao[cur_vao % NV].mask &= ~(1u << i); r_DisableVAA(i); }
static void (*r_VAP)(GLuint, GLint, GLenum, GLboolean, GLsizei, const void *);
static void my_VAP(GLuint i, GLint size, GLenum type, GLboolean norm, GLsizei stride, const void *p) { if (i < 16) vao[cur_vao % NV].sig[i] = (unsigned)size | ((type & 0xff) << 4) | ((unsigned)norm << 12) | ((unsigned)stride << 16); r_VAP(i, size, type, norm, stride, p); }
static void (*r_VAIP)(GLuint, GLint, GLenum, GLsizei, const void *);
static void my_VAIP(GLuint i, GLint size, GLenum type, GLsizei stride, const void *p) { if (i < 16) vao[cur_vao % NV].sig[i] = (unsigned)size | ((type & 0xff) << 4) | (1u << 13) | ((unsigned)stride << 16); r_VAIP(i, size, type, stride, p); }
static void (*r_VAD)(GLuint, GLuint); static void my_VAD(GLuint i, GLuint d) { if (i < 16) vao[cur_vao % NV].div[i] = d; r_VAD(i, d); }
static void (*r_ActiveTexture)(GLenum); static void my_ActiveTexture(GLenum t) { cur_unit = (t - 0x84C0) & 31; r_ActiveTexture(t); }
static void (*r_BindTexture)(GLenum, GLuint); static void my_BindTexture(GLenum tg, GLuint t) { if (tg == 0x0DE1) unit_tex[cur_unit] = t; r_BindTexture(tg, t); }
static void (*r_TexImage2D)(GLenum, GLint, GLint, GLsizei, GLsizei, GLint, GLenum, GLenum, const void *);
static void my_TexImage2D(GLenum tg, GLint lv, GLint ifmt, GLsizei w, GLsizei h, GLint b, GLenum f, GLenum ty, const void *d) { if (tg == 0x0DE1 && lv == 0) { GLuint t = unit_tex[cur_unit] % NT; tex[t].w = w; tex[t].h = h; tex[t].fmt = (GLenum)ifmt; } r_TexImage2D(tg, lv, ifmt, w, h, b, f, ty, d); }
static void (*r_BindFramebuffer)(GLenum, GLuint); static void my_BindFramebuffer(GLenum tg, GLuint f) { if (tg != 0x8CA8) cur_fbo = f; r_BindFramebuffer(tg, f); }
static void (*r_LinkProgram)(GLuint); static void my_LinkProgram(GLuint p) { double a = now_ms(); r_LinkProgram(p); link_ms += now_ms() - a; links_this_frame++; }

static void report(const char *call, GLenum mode, int count, int inst, double ms) {
	init_out();
	if (ms < slow_ms) return;
	GLuint t0 = unit_tex[0] % NT;
	fprintf(out, "frame %ld: %s took %.1f ms | prog %u mode %u count %d inst %d | blend %d (%x %x %x %x eq %x) scissor %d | fbo %u | tex0 %dx%d fmt %x | vao mask %x:", frame, call, ms, cur_prog, mode, count, inst,
			blend_on, bs_rgb, bd_rgb, bs_a, bd_a, beq, scissor_on, cur_fbo, tex[t0].w, tex[t0].h, tex[t0].fmt, vao[cur_vao % NV].mask);
	for (int i = 0; i < 16; i++) if (vao[cur_vao % NV].mask & (1u << i)) fprintf(out, " a%d=%x/d%u", i, vao[cur_vao % NV].sig[i], vao[cur_vao % NV].div[i]);
	fprintf(out, "\n"); fflush(out);
}
static void (*r_DrawArrays)(GLenum, GLint, GLsizei); static void my_DrawArrays(GLenum m, GLint f, GLsizei c) { double a = now_ms(); r_DrawArrays(m, f, c); report("glDrawArrays", m, c, 0, now_ms() - a); }
static void (*r_DrawElements)(GLenum, GLsizei, GLenum, const void *); static void my_DrawElements(GLenum m, GLsizei c, GLenum t, const void *i) { double a = now_ms(); r_DrawElements(m, c, t, i); report("glDrawElements", m, c, 0, now_ms() - a); }
static void (*r_DrawArraysInstanced)(GLenum, GLint, GLsizei, GLsizei); static void my_DrawArraysInstanced(GLenum m, GLint f, GLsizei c, GLsizei n) { double a = now_ms(); r_DrawArraysInstanced(m, f, c, n); report("glDrawArraysInstanced", m, c, n, now_ms() - a); }
static void (*r_DrawElementsInstanced)(GLenum, GLsizei, GLenum, const void *, GLsizei); static void my_DrawElementsInstanced(GLenum m, GLsizei c, GLenum t, const void *i, GLsizei n) { double a = now_ms(); r_DrawElementsInstanced(m, c, t, i, n); report("glDrawElementsInstanced", m, c, n, now_ms() - a); }
static void (*r_Swap)(void *, unsigned long);
static void my_Swap(void *d, unsigned long w) { init_out(); double a = now_ms(); r_Swap(d, w); double ms = now_ms() - a;
	if (links_this_frame) { fprintf(out, "frame %ld: %d programs linked, %.1f ms\n", frame, links_this_frame, link_ms); fflush(out); }
	if (ms >= slow_ms) { fprintf(out, "frame %ld: glXSwapBuffers took %.1f ms\n", frame, ms); fflush(out); }
	links_this_frame = 0; link_ms = 0; frame++; }

#define W(n, mine, real) if (!strcmp(name, n)) { real = (void *)f; return (anyfn)mine; }
static anyfn wrap(const char *name, anyfn f) {
	if (!f) return f;
	W("glUseProgram", my_UseProgram, r_UseProgram) W("glEnable", my_Enable, r_Enable) W("glDisable", my_Disable, r_Disable)
	W("glBlendFunc", my_BlendFunc, r_BlendFunc) W("glBlendFuncSeparate", my_BlendFuncSeparate, r_BlendFuncSeparate) W("glBlendEquation", my_BlendEquation, r_BlendEquation)
	W("glBindVertexArray", my_BindVertexArray, r_BindVertexArray) W("glEnableVertexAttribArray", my_EnableVAA, r_EnableVAA) W("glDisableVertexAttribArray", my_DisableVAA, r_DisableVAA)
	W("glVertexAttribPointer", my_VAP, r_VAP) W("glVertexAttribIPointer", my_VAIP, r_VAIP) W("glVertexAttribDivisor", my_VAD, r_VAD)
	W("glActiveTexture", my_ActiveTexture, r_ActiveTexture) W("glBindTexture", my_BindTexture, r_BindTexture) W("glTexImage2D", my_TexImage2D, r_TexImage2D)
	W("glBindFramebuffer", my_BindFramebuffer, r_BindFramebuffer) W("glLinkProgram", my_LinkProgram, r_LinkProgram)
	W("glDrawArrays", my_DrawArrays, r_DrawArrays) W("glDrawElements", my_DrawElements, r_DrawElements)
	W("glDrawArraysInstanced", my_DrawArraysInstanced, r_DrawArraysInstanced) W("glDrawElementsInstanced", my_DrawElementsInstanced, r_DrawElementsInstanced)
	W("glXSwapBuffers", my_Swap, r_Swap)
	return f;
}
static anyfn my_gpa(const unsigned char *name) { return wrap((const char *)name, real_gpa(name)); }
static anyfn my_gpa_arb(const unsigned char *name) { return wrap((const char *)name, real_gpa_arb(name)); }
void *dlsym(void *handle, const char *name) {
	if (!real_dlsym) real_dlsym = dlvsym(RTLD_NEXT, "dlsym", "GLIBC_2.34");
	if (!real_dlsym) real_dlsym = dlvsym(RTLD_NEXT, "dlsym", "GLIBC_2.2.5");
	void *r = real_dlsym(handle, name);
	if (!r) return r;
	if (!strcmp(name, "glXGetProcAddress")) { real_gpa = (anyfn (*)(const unsigned char *))r; return (void *)my_gpa; }
	if (!strcmp(name, "glXGetProcAddressARB")) { real_gpa_arb = (anyfn (*)(const unsigned char *))r; return (void *)my_gpa_arb; }
	return (void *)wrap(name, (anyfn)r);
}
