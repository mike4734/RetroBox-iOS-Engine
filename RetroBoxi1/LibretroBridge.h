#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
bool rb_core_available(void);
bool rb_load_game(const char *path);
void rb_run_frame(void);
void rb_set_buttons(uint16_t buttons);
const uint32_t *rb_framebuffer(void);
unsigned rb_width(void);
unsigned rb_height(void);
void rb_unload(void);
const char *rb_error(void);
#ifdef __cplusplus
}
#endif
