/// SDL3 Implementation of the HAL
#include "SDL3/SDL_render.h"
#include "SDL3/SDL_video.h"
#include <SDL3/SDL.h>
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL_main.h>

#include "../app.h"
#include "../hal.h"

// Screen scaling from logical size to real size
#define SCREEN_SCALING 5

// SDL3 Application State
// Contains "global" info
struct halstate {
    SDL_Window *window;
    SDL_Renderer *renderer;
};
static struct halstate halstate;

SDL_AppResult SDL_AppInit(void **, int argc, char **argv)
{
    // Initialize SDL3
    SDL_SetAppMetadata("picowy emulator", "1.0", "net.eklipsed.picowy");
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Create the window and renderer
    if (!SDL_CreateWindowAndRenderer(
            "picowy emulator",
            SCREEN_WIDTH * SCREEN_SCALING,
            SCREEN_HEIGHT * SCREEN_SCALING,
            SDL_WINDOW_RESIZABLE,
            &halstate.window,
            &halstate.renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_SetRenderLogicalPresentation(halstate.renderer,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        SDL_LOGICAL_PRESENTATION_LETTERBOX);

    // Initialize the app and continue
    app_init();
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;  /* end the program, reporting success to the OS. */
    }
    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once per frame, and is the heart of the program. */
SDL_AppResult SDL_AppIterate(void *appstate)
{
    const double now = ((double)SDL_GetTicks()) / 1000.0;  /* convert from milliseconds to seconds. */
    /* choose the color for the frame we will draw. The sine wave trick makes it fade between colors smoothly. */
    const float red = (float) (0.5 + 0.5 * SDL_sin(now));
    const float green = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
    const float blue = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));
    SDL_SetRenderDrawColorFloat(halstate.renderer, red, green, blue, SDL_ALPHA_OPAQUE_FLOAT);  /* new color, full alpha. */

    /* clear the window to the draw color. */
    SDL_RenderClear(halstate.renderer);

    /* put the newly-cleared rendering on the screen. */
    SDL_RenderPresent(halstate.renderer);

    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once at shutdown. */
void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
    /* SDL will clean up the window/renderer for us. */
}

bool hal_get_touch_point(struct vec2 *point)
{
    return false;
}
//
// struct vec2 hal_get_accel(void);
//
// void hal_clear_screen(enum color color);
//
// void hal_mask_sprites(uint32_t len, const struct sprite *sprites);
//
// void hal_draw_sprites(uint32_t len, const struct sprite *sprites);
//
// uint32_t hal_power_get_milliamps(void);
//
// uint32_t hal_power_get_battery(void);
//
// bool hal_power_is_charging(void);
