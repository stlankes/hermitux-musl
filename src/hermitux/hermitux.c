#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <sys/select.h>

#ifndef NFDBITS
#define NFDBITS (8*(int)sizeof(long))
#endif

/* This function is defined by Glibc but not Musl, it is supposed to perform
 * some check for stack overflow but for now we just redirect it to the normal
 * print implementation */
int __printf_chk(int flag, const char *restrict fmt, ...) {
	int ret;
	va_list ap;
	va_start(ap, fmt);
	ret = vfprintf(stdout, fmt, ap);
	va_end(ap);
	return ret;
}

int __snprintf_chk(char * s, size_t n, int flag, size_t strlen,
		const char * fmt, ...) {
	int ret;
	va_list ap;
	va_start(ap, fmt);
	ret = vsnprintf(s, n, fmt, ap);
	va_end(ap);
	return ret;
}

void * __memcpy_chk(void * dest, const void * src, size_t len, size_t destlen) {
	return memcpy(dest, src, len);
}

int __sprintf_chk(char * s, int flag, size_t strlen, const char * fmt, ...) {
	int ret;
	va_list ap;
	va_start(ap, fmt);
	ret = vsprintf(s, fmt, ap);
	va_end(ap);
	return ret;
}

int __fprintf_chk(FILE *restrict f, int flag, const char *restrict fmt, ...)
{
	int ret;
	va_list ap;
	va_start(ap, fmt);
	ret = vfprintf(f, fmt, ap);
	va_end(ap);
	return ret;
}

long int __fdelt_chk (long int d) {
	return d / NFDBITS;
}

int __vsnprintf_chk(char * s, size_t maxlen, int flag, size_t slen, const char * format, va_list args) {
	return vsnprintf(s, maxlen, format, args);
}

int __vfprintf_chk(FILE * fp, int flag, const char * format, va_list ap) {
	return vfprintf(fp, format, ap);
}
