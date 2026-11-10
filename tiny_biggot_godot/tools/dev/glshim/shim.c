// LD_PRELOAD shim: reports when the game links a shader program, and how long it took, by frame.
// The engine loads GL through dlopen/dlsym and glXGetProcAddress, so those are the calls wrapped.
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

typedef void (*anyfn)(void);
static void *(*real_dlsym)(void *, const char *);
static anyfn (*real_gpa)(const unsigned char *);
static anyfn (*real_gpa_arb)(const unsigned char *);
static void (*real_link)(unsigned);
static void (*real_compile)(unsigned);
static void (*real_swap)(void *, unsigned long);
static long frame = 0;
static int links_this_frame = 0, compiles_this_frame = 0;
static double ms_this_frame = 0.0;
static FILE *out;

static double now_ms(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec * 1000.0 + t.tv_nsec / 1e6; }
static void init_out(void) { if (!out) { const char *p = getenv("GLSHIM_LOG"); out = p ? fopen(p, "w") : stderr; } }

static void my_link(unsigned prog) { double a = now_ms(); real_link(prog); ms_this_frame += now_ms() - a; links_this_frame++; }
static void my_compile(unsigned sh) { double a = now_ms(); real_compile(sh); ms_this_frame += now_ms() - a; compiles_this_frame++; }
static void my_swap(void *dpy, unsigned long drawable) {
	init_out();
	if (links_this_frame || compiles_this_frame) {
		fprintf(out, "frame %ld: %d programs linked, %d shaders compiled, %.1f ms\n", frame, links_this_frame, compiles_this_frame, ms_this_frame);
		fflush(out);
	}
	links_this_frame = compiles_this_frame = 0; ms_this_frame = 0.0;
	frame++;
	real_swap(dpy, drawable);
}
static anyfn wrap(const char *name, anyfn f) {
	if (getenv("GLSHIM_NAMES") && (strstr(name, "Link") || strstr(name, "CompileShader") || strstr(name, "Swap"))) fprintf(stderr, "[shim] lookup %s -> %p\n", name, (void *)f);
	if (!f) return f;
	if (!strcmp(name, "glLinkProgram")) { real_link = (void (*)(unsigned))f; return (anyfn)my_link; }
	if (!strcmp(name, "glCompileShader")) { real_compile = (void (*)(unsigned))f; return (anyfn)my_compile; }
	if (!strcmp(name, "glXSwapBuffers")) { real_swap = (void (*)(void *, unsigned long))f; return (anyfn)my_swap; }
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
