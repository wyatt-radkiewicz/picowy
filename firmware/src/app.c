//
// picowy main firmware
//
#include "app.h"
#include "hal.h"

void app_init(void)
{
    return;
}

void app_loop(void)
{
    struct vec2 touch_point;
    if (hal_get_touch_point(&touch_point)) {
        hal_draw_rect(COLOR_WHITE, fixed16_int(touch_point.x), fixed16_int(touch_point.y), 1, 1);
    }
}

void app_deinit(void)
{
    return;
}
