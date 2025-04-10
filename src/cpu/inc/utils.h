#ifndef INC_UTILS_H_
#define INC_UTILS_H_

#ifdef __cplusplus
#define restrict
#endif

inline static uint16_t max(uint32_t a, uint32_t b) { return a < b ? b : a; }

inline static void memcpy_volatile(volatile void *restrict dst, const volatile void *restrict src, uint32_t cnt) {
  const volatile unsigned char *src_c = (const volatile unsigned char *)src;
  volatile unsigned char *dst_c = (volatile unsigned char *)dst;
  while (cnt-- > 0) *dst_c++ = *src_c++;
}

inline static void memset_volatile(volatile void *restrict dst, const int value, uint32_t cnt) {
  const unsigned char value_c = value & 0xFF;
  volatile unsigned char *dst_c = (volatile unsigned char *)dst;
  while (cnt-- > 0) *dst_c++ = value_c;
}

inline static void word_cpy(uint16_t *dst, uint16_t *src, uint32_t cnt) {
  while (cnt-- > 0) *dst++ = *src++;
}

inline static void word_cpy_volatile(volatile uint16_t *dst, volatile const uint16_t *src, uint32_t cnt) {
  while (cnt-- > 0) *dst++ = *src++;
}

#endif  // INC_UTILS_H_
