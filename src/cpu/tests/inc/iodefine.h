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

extern st_ecatc_t ECATC;

#ifdef __cplusplus
}
#endif
