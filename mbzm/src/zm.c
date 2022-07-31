/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Example usage of Zmodem implementation
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "fat.h"
#include "comms.h"
#include "zmodem.h"

// Spec says a data packet is max 1024 bytes, but add some headroom...
#define DATA_BUF_LEN    2048

//FILE* const stdout;

int main(int argc, char **argv) {
  uint8_t rzr_buf[4];
  uint8_t data_buf[DATA_BUF_LEN];
  uint16_t count;
  uint32_t received_data_size = 0;
  ZHDR hdr;
  FILE *out = NULL;

#ifdef ZDEBUG_DUMP_BAD_BLOCKS
  uint32_t bad_block_count = 0;
#endif

  printf("68030 ZModem, Damian Wildie, 19/07/2022 V0.0.1\r\n");
//  printf("argc = %d\r\n", argc);
//  for (int i = 0; i < argc; i++) {
//    printf("argv[%d]: %s\r\n", i, argv[i]);
//  }

  if (initCommPort(argc, argv)) {
    //DEBUGF("Opened port just fine\r\n");

    printf("Awaiting remote transfer initiation...\r\n");

    if (zm_await("rz\r", (char*)rzr_buf, 4) == OK) {
      DEBUGF("Got rzr...\r\n");

      while (true) {
startframe:
        DEBUGF("\n====================================\r\n");
        uint16_t result = zm_await_header(&hdr);

        switch (result) {
        case CANCELLED:
          printf("Transfer cancelled by remote; Bailing...\r\n");
          goto cleanup;
        case OK:
          DEBUGF("Got valid header\r\n");

          switch (hdr.type) {
          case ZRQINIT:
          case ZEOF:
            DEBUGF("Is ZRQINIT or ZEOF\r\n");

            result = zm_send_flags_hdr(ZRINIT, CANOVIO | CANFC32, 0, 0, 0);

            if (result == CANCELLED) {
              printf("Transfer cancelled by remote; Bailing...\r\n");
              goto cleanup;
            } else if (result == OK) {
              DEBUGF("Send ZRINIT was OK\r\n");
            } else if(result == CLOSED) {
              printf("Connection closed prematurely; Bailing...\r\n");
              goto cleanup;
            }

            continue;

          case ZFIN:
            DEBUGF("Is ZFIN\r\n");

            result = zm_send_pos_hdr(ZFIN, 0);

            if (result == CANCELLED) {
              printf("Transfer cancelled by remote; Bailing...\r\n");
              goto cleanup;
            } else if (result == OK) {
              DEBUGF("Send ZFIN was OK\r\n");
            } else if(result == CLOSED) {
              printf("Connection closed prematurely; Bailing...\r\n");
            }

            // Consume any trailing characters from the host
            zm_flush();

            printf("Transfer complete; Received %0d byte(s)\r\n", received_data_size);
            goto cleanup;

          case ZFILE:
            DEBUGF("Is ZFILE\r\n");

            switch (hdr.flags.f0) {
            case 0:     /* no special treatment - default to ZCBIN */
            case ZCBIN:
              DEBUGF("--> Binary receive\r\n");
              break;
            case ZCNL:
              DEBUGF("--> ASCII Receive; Fix newlines (IGNORED - NOT SUPPORTED)\r\n");
              break;
            case ZCRESUM:
              DEBUGF("--> Resume interrupted transfer (IGNORED - NOT SUPPORTED)\r\n");
              break;
            default:
              printf("WARN: Invalid conversion flag [0x%02x] (IGNORED - Assuming Binary)\r\n", hdr.flags.f0);
            }

            count = DATA_BUF_LEN;
            result = zm_read_data_block(data_buf, &count);
            DEBUGF("Result of data block read is [0x%04x] (got %d character(s))\r\n", result, count);

            if (result == CANCELLED) {
              printf("Transfer cancelled by remote; Bailing...\r\n");
              goto cleanup;
            } else if (!IS_ERROR(result)) {
              printf("Receiving file: '%s'\r\n", data_buf);

              out = fl_fopen((char*)data_buf, "wb");
              if (out == NULL) {
                printf("Error opening file for output; Bailing...\r\n");
                goto cleanup;
              }

              result = zm_send_pos_hdr(ZRPOS, received_data_size);

              if (result == CANCELLED) {
                printf("Transfer cancelled by remote; Bailing...\r\n");
                goto cleanup;
              } else if (result == OK) {
                  DEBUGF("Send ZRPOS was OK\r\n");
              } else if(result == CLOSED) {
                  printf("Connection closed prematurely; Bailing...\r\n");
                  goto cleanup;
              }
            }

            // TODO care about XON that will follow?

            continue;

          case ZDATA:
            DEBUGF("Is ZDATA\r\n");

            while (true) {
              count = DATA_BUF_LEN;
              result = zm_read_data_block(data_buf, &count);
              DEBUGF("Result of data block read is [0x%04x] (got %d character(s))\r\n", result, count);

              if (out == NULL) {
                printf("Received data before open file; Bailing...\r\n");
                goto cleanup;
              }

              if (result == CANCELLED) {
                printf("Transfer cancelled by remote; Bailing...\r\n");
                goto cleanup;
              } else if (!IS_ERROR(result)) {
                DEBUGF("Received %d byte(s) of data\r\n", count);

                fl_fwrite(data_buf, count - 1, 1, out);
                received_data_size += (count - 1);

                if (result == GOT_CRCE) {
                  // End of frame, header follows, no ZACK expected.
                  DEBUGF("Got CRCE; Frame done [NOACK] [Pos: 0x%08x]\r\n", received_data_size);
                  break;
                } else if (result == GOT_CRCG) {
                  // Frame continues, non-stop (another data packet follows)
                  DEBUGF("Got CRCG; Frame continues [NOACK] [Pos: 0x%08x]\r\n", received_data_size);
                  continue;
                } else if (result == GOT_CRCQ) {
                  // Frame continues, ZACK required
                  DEBUGF("Got CRCQ; Frame continues [ACK] [Pos: 0x%08x]\r\n", received_data_size);

                  result = zm_send_pos_hdr(ZACK, received_data_size);

                  if (result == CANCELLED) {
                    printf("Transfer cancelled by remote; Bailing...\r\n");
                    goto cleanup;
                  } else if (result == OK) {
                    DEBUGF("Send ZACK was OK\r\n");
                  } else if(result == CLOSED) {
                    printf("Connection closed prematurely; Bailing...\r\n");
                    goto cleanup;
                  }

                  continue;
                } else if (result == GOT_CRCW) {
                  // End of frame, header follows, ZACK expected.
                  DEBUGF("Got CRCW; Frame done [ACK] [Pos: 0x%08x]\r\n", received_data_size);

                  result = zm_send_pos_hdr(ZACK, received_data_size);

                  if (result == CANCELLED) {
                    printf("Transfer cancelled by remote; Bailing...\r\n");
                    goto cleanup;
                  } else if (result == OK) {
                    DEBUGF("Send ZACK was OK\r\n");
                  } else if(result == CLOSED) {
                    printf("Connection closed prematurely; Bailing...\r\n");
                    goto cleanup;
                  }

                  break;
                }

              } else {
                DEBUGF("Error while receiving block: 0x%04x\r\n", result);

                result = zm_send_pos_hdr(ZRPOS, received_data_size);

#ifdef ZDEBUG_DUMP_BAD_BLOCKS
                char name[20];
                snprintf(name, 20, "block%d.bin", bad_block_count++);
                DEBUGF("  >> Writing file '%s'\r\n", name);
                FILE *block = fl_fopen(name, "wb");
                fl_fwrite(data_buf,count,1,block);
                fl_fclose(block);
#endif

                if (result == CANCELLED) {
                  printf("Transfer cancelled by remote; Bailing...\r\n");
                  goto cleanup;
                } else if (result == OK) {
                  DEBUGF("Send ZRPOS was OK\r\n");
                  goto startframe;
                } else if(result == CLOSED) {
                  printf("Connection closed prematurely; Bailing...\r\n");
                  goto cleanup;
                }
              }
            }

            continue;

          default:
            printf("WARN: Ignoring unknown header type 0x%02x\r\n", hdr.type);
            continue;
          }

          break;
        case BAD_CRC:
          DEBUGF("Didn't get valid header - CRC Check failed\r\n");

          result = zm_send_pos_hdr(ZNAK, received_data_size);

          if (result == CANCELLED) {
            printf("Transfer cancelled by remote; Bailing...\r\n");
            goto cleanup;
          } else if (result == OK) {
            DEBUGF("Send ZNACK was OK\r\n");
          } else if(result == CLOSED) {
            printf("Connection closed prematurely; Bailing...\r\n");
            goto cleanup;
          }

          continue;
        default:
          DEBUGF("Didn't get valid header - result is 0x%04x\r\n", result);

          result = zm_send_pos_hdr(ZNAK, received_data_size);

          if (result == CANCELLED) {
            printf("Transfer cancelled by remote; Bailing...\r\n");
            goto cleanup;
          } else if (result == OK) {
            DEBUGF("Send ZNACK was OK\r\n");
          } else if(result == CLOSED) {
            printf("Connection closed prematurely; Bailing...\r\n");
            goto cleanup;
          }

          continue;
        }
      }
    }

    cleanup:
    
    if (out != NULL) {
      fl_fclose(out);
    }

    closeCommPort();

  } else {
    printf("Unable to open port\r\n");
    return 2;
  }

  return 0;
}


