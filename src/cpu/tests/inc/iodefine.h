#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  union {
    unsigned short WORD;
    struct {
      unsigned short STATUSCODE : 16;
    } BIT;
  } AL_STATUS_CODE;
  union {
    unsigned long long LONGLONG;
  } DC_SYS_TIME;
} st_ecatc_t;

typedef struct {
  union {
    unsigned char BYTE;
  } PODR;
} st_porta_t;

extern st_ecatc_t ECATC;
extern st_porta_t PORTA;

#ifdef __cplusplus
}
#endif
