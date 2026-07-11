//
// picowy main firmware
//
#include "app.h"
#include "hal.h"

#define MAX_SPRITES 64

// Application state
struct appstate {
    // Touch calibration data
    struct {
        struct vec2 points[4];
        uint32_t npoints;

        struct vec2 offset;
        struct vec2 scale;
    } touch_panel_calib;

    // Screen data
    struct {
        struct sprite sprites[64];
        uint32_t nsprites;
    } screen;
};
struct appstate appstate;

void app_init(void)
{
}

void app_loop(void)
{
}

void app_deinit(void)
{
}
