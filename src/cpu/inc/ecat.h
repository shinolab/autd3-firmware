#ifndef INC_ECAT_H_
#define INC_ECAT_H_

#include "app.h"

typedef struct {
  uint16_t data[313];
} RX_STR;

typedef struct {
  uint16_t reserved;
  uint16_t ack;
} TX_STR;

typedef struct {
  uint8_t msg_id;
  uint8_t _pad;
  uint16_t slot_2_offset;
} Header;

#endif  // INC_ECAT_H_
