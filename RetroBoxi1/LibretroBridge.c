#include "LibretroBridge.h"
#include "libretro.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
/* Linking an actual iOS Libretro core enables the engine. These weak symbols
   permit UI-only builds without pretending a core is included. */
#define WEAK __attribute__((weak_import))
extern void retro_set_environment(retro_environment_t) WEAK;
extern void retro_set_video_refresh(retro_video_refresh_t) WEAK;
extern void retro_set_audio_sample(retro_audio_sample_t) WEAK;
extern void retro_set_audio_sample_batch(retro_audio_sample_batch_t) WEAK;
extern void retro_set_input_poll(retro_input_poll_t) WEAK;
extern void retro_set_input_state(retro_input_state_t) WEAK;
extern void retro_init(void) WEAK;
extern void retro_deinit(void) WEAK;
extern void retro_get_system_info(struct retro_system_info *) WEAK;
extern void retro_get_system_av_info(struct retro_system_av_info *) WEAK;
extern bool retro_load_game(const struct retro_game_info *) WEAK;
extern void retro_unload_game(void) WEAK;
extern void retro_run(void) WEAK;
static uint32_t *pixels;
static unsigned w,h;
static uint16_t buttons;
static unsigned pixel_format=RETRO_PIXEL_FORMAT_0RGB1555;
static bool initialized,loaded;
static char error_msg[256]="No hay core Libretro para iOS enlazado.";
static char *game_bytes;
static char *game_path;
static size_t game_size;
static const char *system_directory=".";
static bool environment(unsigned cmd,void *data) {
 if(cmd==RETRO_ENVIRONMENT_SET_PIXEL_FORMAT && data) {unsigned fmt=*(unsigned*)data; if(fmt<=2){pixel_format=fmt;return true;}return false;}
 if((cmd==RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY || cmd==RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY) && data) {*(const char**)data=system_directory;return true;}
 return false;
}
static void video(const void *data,unsigned width,unsigned height,size_t pitch) {
 if(!data || !width || !height || width>4096 || height>4096) return;
 if(width!=w || height!=h) {uint32_t *next=realloc(pixels,(size_t)width*height*4);if(!next)return;pixels=next;w=width;h=height;}
 for(unsigned y=0;y<height;y++)for(unsigned x=0;x<width;x++){
  uint32_t rgb=0; if(pixel_format==RETRO_PIXEL_FORMAT_XRGB8888){rgb=((const uint32_t*)((const uint8_t*)data+y*pitch))[x]&0xFFFFFF;}
  else {uint16_t v=((const uint16_t*)((const uint8_t*)data+y*pitch))[x];
   if(pixel_format==RETRO_PIXEL_FORMAT_RGB565) rgb=(((v>>11)&31)*255/31<<16)|(((v>>5)&63)*255/63<<8)|((v&31)*255/31);
   else rgb=(((v>>10)&31)*255/31<<16)|(((v>>5)&31)*255/31<<8)|((v&31)*255/31);
  } pixels[(size_t)y*width+x]=0xFF000000|rgb;
 }
}
static void audio_sample(int16_t l,int16_t r){(void)l;(void)r; /* TODO: AVAudioEngine ring buffer */}
static size_t audio_batch(const int16_t *data,size_t frames){(void)data;return frames; /* TODO: real audio output */}
static void input_poll(void){}
static int16_t input_state(unsigned port,unsigned device,unsigned index,unsigned id){(void)index;return (port==0&&device==RETRO_DEVICE_JOYPAD&&id<16)?((buttons>>id)&1):0;}
bool rb_core_available(void){return retro_init && retro_set_environment && retro_set_video_refresh && retro_set_audio_sample && retro_set_audio_sample_batch && retro_set_input_poll && retro_set_input_state && retro_load_game && retro_run && retro_unload_game && retro_deinit && retro_get_system_info;}
const char *rb_error(void){return error_msg;}
void rb_set_buttons(uint16_t b){buttons=b;}
const uint32_t *rb_framebuffer(void){return pixels;}
unsigned rb_width(void){return w;}
unsigned rb_height(void){return h;}
void rb_unload(void){if(loaded){retro_unload_game();loaded=false;}if(initialized){retro_deinit();initialized=false;}free(game_bytes);game_bytes=NULL;free(game_path);game_path=NULL;game_size=0;buttons=0;}
bool rb_load_game(const char *path){
 rb_unload();if(!rb_core_available()){snprintf(error_msg,sizeof(error_msg),"Falta enlazar un core Libretro iOS (por ejemplo FCEUmm NES).");return false;}
 FILE *f=fopen(path,"rb");if(!f){snprintf(error_msg,sizeof(error_msg),"No se pudo abrir la ROM.");return false;}
 if(fseek(f,0,SEEK_END)!=0){fclose(f);return false;}long n=ftell(f);rewind(f);
 if(n<=0||n>128*1024*1024){fclose(f);snprintf(error_msg,sizeof(error_msg),"ROM vacía o demasiado grande.");return false;}
 game_bytes=malloc((size_t)n);game_path=strdup(path);
 if(!game_bytes||!game_path||fread(game_bytes,1,(size_t)n,f)!=(size_t)n){fclose(f);rb_unload();return false;}fclose(f);game_size=(size_t)n;
 retro_set_environment(environment);retro_set_video_refresh(video);retro_set_audio_sample(audio_sample);retro_set_audio_sample_batch(audio_batch);retro_set_input_poll(input_poll);retro_set_input_state(input_state);
 retro_init();initialized=true;
 struct retro_system_info info={0};retro_get_system_info(&info);
 struct retro_game_info game={.path=game_path,.data=info.need_fullpath?NULL:game_bytes,.size=info.need_fullpath?0:game_size,.meta=NULL};
 if(!retro_load_game(&game)){snprintf(error_msg,sizeof(error_msg),"El core rechazó la ROM.");rb_unload();return false;}
 loaded=true;error_msg[0]=0;return true;
}
void rb_run_frame(void){if(loaded)retro_run();}
