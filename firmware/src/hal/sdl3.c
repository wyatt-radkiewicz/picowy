/// SDL3 Implementation of the HAL
#include <SDL3/SDL.h>
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL_main.h>
#include <math.h>

#include "../app.h"
#include "../hal.h"

// Emulated battery capacity in milliamp hours
#define BATTERY_CAPACITY 105.0f

// SDL3 Application State
// Contains "global" info
struct halstate {
    // SDL3 Application level members
    SDL_Window *window;
    SDL_Renderer *renderer;
    SDL_Time last_tick;
    float loop_duration;

    // Interaction members
    float grab_start_angle, grab_current_angle;
    float mouse_x, mouse_y;
    bool mouse_left;
    bool mouse_right;
    bool mouse_middle;
    int grab_turns;

    // Screen rendering
    SDL_Texture *texture;
    uint8_t screen[SCREEN_WIDTH * SCREEN_HEIGHT / 8];
    float screen_size;

    // Device level members
    float device_angle, grabbed_device_angle;
    float device_angular_vel;
    float battery_capacity;
    float average_milliamps;
    bool is_charging;
};
static struct halstate halstate = {};

//
// Utility functions
//
static inline fixed16_t fixed16_from_float(float x)
{
    if (x <= -128.0f) {
        return -128.0f;
    } else if (x >= 127.0f + 255.0f / 256.0f) {
        return 127.0f + 255.0f / 256.0f;
    }

    return fixed16_init((int8_t)floorf(x), (uint32_t)floorf(x * 255.0f) & 0xff);
}

//
// Start functions
//

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
            SCREEN_WIDTH * 5,
            SCREEN_HEIGHT * 5,
            SDL_WINDOW_RESIZABLE,
            &halstate.window,
            &halstate.renderer)) {
        SDL_Log("Couldn't create window and renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Get the renderer properties
    SDL_PropertiesID renderer_props = SDL_GetRendererProperties(halstate.renderer);
    if (renderer_props == 0) {
        SDL_Log("Could not retrieve renderer properties: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Get the renderer's perffered pixel formats
    const SDL_PixelFormat *renderer_formats = SDL_GetPointerProperty(
        renderer_props,
        SDL_PROP_RENDERER_TEXTURE_FORMATS_POINTER,
        nullptr);
    if (!renderer_formats) {
        SDL_Log("Could not query renderer pixel format: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Get the first one, or the one that the window supports
    SDL_PixelFormat renderer_format = renderer_formats[0];
    if (renderer_format == SDL_PIXELFORMAT_UNKNOWN
        && (renderer_format = SDL_GetWindowPixelFormat(halstate.window))
            == SDL_PIXELFORMAT_UNKNOWN) {
        SDL_Log("Could not query window pixel format: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Create a texture to stream the screen bitmap to
    if (!(halstate.texture = SDL_CreateTexture(
              halstate.renderer,
              renderer_format,
              SDL_TEXTUREACCESS_STREAMING,
              SCREEN_WIDTH,
              SCREEN_HEIGHT))) {
        SDL_Log("Could not create screen texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_SetTextureScaleMode(halstate.texture, SDL_SCALEMODE_NEAREST);

    // Initialize other members of the halstate
    SDL_GetCurrentTime(&halstate.last_tick);
    halstate.battery_capacity = BATTERY_CAPACITY;
    halstate.loop_duration = 1.0f / (float)HAL_HZ;

    // Initialize the app and continue
    app_init();
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *, SDL_Event *event)
{
    switch (event->type) {
    // Quit the emulator if user requests it
    case SDL_EVENT_QUIT:
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *)
{
    // Get current window size
    int window_w, window_h;
    SDL_GetWindowSize(halstate.window, &window_w, &window_h);
    float window_centerx = (float)window_w / 2.0f;
    float window_centery = (float)window_h / 2.0f;

    // Get elapsed time
    SDL_Time current_tick;
    SDL_GetCurrentTime(&current_tick);
    float elapsed_time = (float)(current_tick - halstate.last_tick) / 1e9f;
    halstate.last_tick = current_tick;
    if (elapsed_time <= 0.0f) {
        elapsed_time = 1e-9f;
    } else if (elapsed_time >= 0.1f) {
        elapsed_time = 0.1f;
    }

    // Get the new mouse state
    float mouse_x, mouse_y;
    SDL_MouseButtonFlags mouse_buttons = SDL_GetMouseState(&mouse_x, &mouse_y);
    mouse_x -= window_centerx;
    mouse_y -= window_centery;
    halstate.mouse_left = mouse_buttons & SDL_BUTTON_LMASK;

    // Rotate the device
    if (mouse_buttons & SDL_BUTTON_RMASK) {
        // Apply turns
        if (mouse_y < 0.0f) {
            if (mouse_x <= 0.0f && halstate.mouse_x > 0.0f) {
                halstate.grab_turns += 1;
            } else if (mouse_x >= 0.0f && halstate.mouse_x < 0.0f) {
                halstate.grab_turns -= 1;
            }
        }

        // Update the current grabbing angle
        halstate.grab_current_angle = atan2f(mouse_x, mouse_y)
            + (float)halstate.grab_turns * M_PI * 2.0f;

        // Right mouse button was just pressed
        if (!halstate.mouse_right) {
            halstate.grab_start_angle = halstate.grab_current_angle;
            halstate.grabbed_device_angle = halstate.device_angle;
        }

        // Drag the current device angle to the angle we want it to be at
        float mouse_grab_delta = halstate.grab_current_angle - halstate.grab_start_angle;
        float wanted_device_angle = halstate.grabbed_device_angle + mouse_grab_delta;
        halstate.device_angular_vel = (wanted_device_angle - halstate.device_angle) * 0.9f;
        halstate.device_angular_vel /= 0.1f;
    } else {
        halstate.grab_turns = 0;
    }
    halstate.mouse_right = mouse_buttons & SDL_BUTTON_RMASK;
    halstate.mouse_x = mouse_x;
    halstate.mouse_y = mouse_y;

    // Apply the angular momentum to the device
    halstate.device_angle += halstate.device_angular_vel * elapsed_time;
    halstate.device_angular_vel *= expf(elapsed_time * -6.0f);

    // Apply charging logic
    if (!halstate.mouse_middle && (mouse_buttons & SDL_BUTTON_MMASK)) {
        // Swap charging state
        halstate.is_charging = !halstate.is_charging;
    }
    if (halstate.is_charging) {
        halstate.battery_capacity += elapsed_time * 0.01f;
        if (halstate.battery_capacity > BATTERY_CAPACITY) {
            halstate.battery_capacity = BATTERY_CAPACITY;
        }
    } else {
        halstate.battery_capacity -= elapsed_time * halstate.average_milliamps / 60.0f / 60.0f;
        if (halstate.battery_capacity < 0.0f) {
            halstate.battery_capacity = 0.0f;
        }
    }

    // Update the app
    halstate.loop_duration += elapsed_time;
    if (halstate.loop_duration >= 1.0f / (float)HAL_HZ) {
        halstate.loop_duration = 0;
        app_loop();
    }

    // Lock the texture we will draw to the screen
    SDL_Surface *texture_pixels;
    if (!SDL_LockTextureToSurface(halstate.texture, nullptr, &texture_pixels)) {
        SDL_Log("Couldn't lock screen texture for write access: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Update the pixels
    for (uint32_t y = 0; y < SCREEN_HEIGHT; y++) {
        for (uint32_t x = 0; x < SCREEN_WIDTH; x++) {
            uint8_t r, g, b;
            if (halstate.screen[y * (SCREEN_WIDTH / 8) + (x / 8)] & 1 << (x % 8)) {
                r = 240;
                g = 240;
                b = 240;
            } else {
                r = 10;
                g = 10;
                b = 10;
            }
            SDL_WriteSurfacePixel(texture_pixels, x, y, r, g, b, 255);
        }
    }
    SDL_UnlockTexture(halstate.texture);

    // Render it to the screen
    halstate.screen_size = (float)SDL_min(window_w, window_h) * 0.7f;
    SDL_SetRenderDrawColor(halstate.renderer, 0, 30, 50, 255);
    SDL_RenderClear(halstate.renderer);
    SDL_RenderTextureRotated(
        halstate.renderer,
        halstate.texture,
        nullptr,
        &(const SDL_FRect) {
            .x = window_centerx - halstate.screen_size / 2.0f,
            .y = window_centery - halstate.screen_size / 2.0f,
            .w = halstate.screen_size,
            .h = halstate.screen_size,
        },
        halstate.device_angle / M_PI * -180.0f,
        nullptr,
        SDL_FLIP_NONE);
    SDL_RenderPresent(halstate.renderer);
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *, SDL_AppResult)
{
    app_deinit();
    SDL_DestroyTexture(halstate.texture);
}

//
// HAL functions
//

bool hal_get_touch_point(struct vec2 *point)
{
    if (!halstate.mouse_left) {
        return false;
    }

    float mouse_x = halstate.mouse_x * cosf(halstate.device_angle)
        - halstate.mouse_y * sinf(halstate.device_angle);
    float mouse_y = halstate.mouse_x * sinf(halstate.device_angle)
        + halstate.mouse_y * cosf(halstate.device_angle);
    mouse_x += halstate.screen_size / 2.0f;
    mouse_y += halstate.screen_size / 2.0f;
    mouse_x *= (float)SCREEN_WIDTH / halstate.screen_size;
    mouse_y *= (float)SCREEN_WIDTH / halstate.screen_size;

    if (mouse_x < 0
        || mouse_y < 0
        || mouse_x >= (float)SCREEN_WIDTH
        || mouse_y >= (float)SCREEN_HEIGHT) {
        return false;
    }

    *point = (struct vec2) {
        .x = fixed16_from_float(mouse_x),
        .y = fixed16_from_float(mouse_y),
    };
    return true;
}

struct vec2 hal_get_accel(void)
{
    return (struct vec2) {
        .x = fixed16_from_float(sinf(halstate.device_angle)),
        .y = fixed16_from_float(cosf(halstate.device_angle)),
    };
}

void hal_draw_rect(enum color color, int8_t x, int8_t y, uint8_t w, uint8_t h)
{
    for (int32_t dsty = y; dsty < y + h; dsty++) {
        for (int32_t dstx = x; dstx < x + w; dstx++) {
            if (dsty < 0 || dstx < 0 || dsty >= SCREEN_HEIGHT || dstx >= SCREEN_WIDTH) {
                continue;
            }

            uint8_t *byte = &halstate.screen[dsty * (SCREEN_WIDTH / 8) + (dstx / 8)];
            const uint8_t bit = 1 << (dstx % 8);

            switch (color) {
            case COLOR_BLACK:
                *byte &= ~bit;
            case COLOR_WHITE:
            default:
                *byte |= bit;
            }
        }
    }
}

void hal_draw_sprite(const struct sprite *this)
{
    for (int32_t y = this->y; y < this->y + this->h; y++) {
        for (int32_t x = this->x; x < this->x + this->w; x++) {
            if (y < 0 || x < 0 || y >= SCREEN_HEIGHT || x >= SCREEN_WIDTH) {
                continue;
            }

            const uint32_t src_x = x - this->x;
            const uint32_t src_y = y - this->y;
            uint8_t *dst_byte = &halstate.screen[y * (SCREEN_WIDTH / 8) + (x / 8)];
            const uint8_t src_byte = this->bitmap[src_y * this->w + (src_x / 8)];
            const uint8_t dst_bit = 1 << (x % 8);
            const uint8_t src_bit = 1 << (src_x % 8);

            if (src_byte & src_bit) {
                *dst_byte |= dst_bit;
            } else {
                *dst_byte &= dst_bit;
            }
        }
    }
}

uint32_t hal_power_get_milliamps(void)
{
    return (uint32_t)roundf(halstate.average_milliamps);
}

uint32_t hal_power_get_battery(void)
{
    return halstate.battery_capacity / BATTERY_CAPACITY * 100.0f;
}

bool hal_power_is_charging(void)
{
    return halstate.is_charging;
}
