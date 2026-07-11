//
// picowy specific project HAL
//
#ifndef _HAL_H_
#define _HAL_H_
#include <stddef.h>
#include <stdint.h>

//
// HAL MATH
//

// Fixed 8.8 signed integer, backed by a 16 bit signed integer
typedef int16_t fixed16_t;

// Creates a fixed 8.8 integer from both the integral and fractional parts
inline fixed16_t fixed16_init(int8_t int_part, uint8_t frac_part)
{
    return int_part << 8 | frac_part;
}

// Adds both fixed point numbers together
inline fixed16_t fixed16_add(fixed16_t lhs, fixed16_t rhs)
{
    return lhs + rhs;
}

// Subtract rhs from lhs
inline fixed16_t fixed16_sub(fixed16_t lhs, fixed16_t rhs)
{
    return lhs - rhs;
}

// Multiply lhs by rhs
inline fixed16_t fixed16_mul(fixed16_t lhs, fixed16_t rhs)
{
    return lhs * rhs >> 8;
}

// Returns the square root of the fixed point number.
// If `this` is less than 0, it returns 0 (instead of showing an error).
inline fixed16_t fixed16_sqrt(fixed16_t this)
{
    // Digit by digit algorithm
    if (this <= 0)
        return 0;
    uint16_t opposite = this;
    uint16_t result = 0;

    // `bit` starts at highest power of 4
    uint16_t bit = 1;
    while (bit <= opposite)
        bit <<= 2;
    bit >>= 2;

    while (bit != 0) {
        uint16_t delta_sqr = result + bit;
        if (opposite >= delta_sqr) {
            opposite -= delta_sqr;
            result += bit << 1;
        }
        result >>= 1;
        bit >>= 2;
    }
    return result;
}

// Fixed 8.8, 2 element vector
struct vec2 {
    fixed16_t x;
    fixed16_t y;
};

// Add both vectors element-wise
inline struct vec2 vec2_add(struct vec2 lhs, struct vec2 rhs)
{
    return (struct vec2) { .x = lhs.x + rhs.x, .y = lhs.x + rhs.y };
}

// Subtract rhs from lhs element-wise
inline struct vec2 vec2_sub(struct vec2 lhs, struct vec2 rhs)
{
    return (struct vec2) { .x = lhs.x - rhs.x, .y = lhs.x - rhs.y };
}

// Multiply lhs by rhs element-wise
inline struct vec2 vec2_mul(struct vec2 lhs, struct vec2 rhs)
{
    return (struct vec2) { .x = lhs.x * rhs.x, .y = lhs.x * rhs.y };
}

// Computes the dot product of lhs and rhs
inline fixed16_t vec2_dot(struct vec2 lhs, struct vec2 rhs)
{
    return lhs.x * rhs.x + lhs.y * rhs.y;
}

// Returns the magnitude of the vector
inline fixed16_t vec2_mag(struct vec2 this)
{
    return fixed16_sqrt(this.x * this.x + this.y * this.y);
}

//
// HAL Touch Panel
//

// Returns `true` if the touch panel is being pressed down, and stores the result in `point`
// (0.0   , 0.0   )---------------(255.0 , 0.0   )
//        |                              |
//        |         Touch Panel          |
//        |                              |
// (0.0   , 255.0 )---------------(255.0 , 255.0 )
bool hal_get_touch_point(struct vec2 *point);

//
// HAL Accelerometer
//

// Returns the acceleration vector projected onto the screen's coordinate space.
// Positive X is to the right of the screen, positive Y is to the bottom of the screen.
struct vec2 hal_get_accel(void);

//
// HAL OLED Screen
//

// How big the screen is in pixels
enum screen_size : uint32_t {
    SCREEN_WIDTH = 128,
    SCREEN_HEIGHT = 128,
};

// Black is '0' and white is '1'
enum color : bool {
    COLOR_BLACK,
    COLOR_WHITE,
};

// Writes all '0's or '1's to the area in the rectangle
void rect_draw(enum color color, int8_t x, int8_t y, uint8_t w, uint8_t h);

// Represents a sprite that will be shown to the screen.
// `bitmap` points to a row major monochrome bitmap of width `w` and height `h`.
// Sprites are clipped to the screen boundaries, and don't wrap around.
struct sprite {
    const uint8_t *bitmap;

    int8_t x;
    int8_t y;
    uint8_t w;
    uint8_t h;
};

// Draws the sprite to the screen
void sprite_draw(const struct sprite *this);

//
// HAL Power Diagnostics
//

// Returns the average amount of milliamps being pulled by the main system
uint32_t hal_power_get_milliamps(void);

// Returns the amount of battery left in percent
uint32_t hal_power_get_battery(void);

// Returns whether or not picowy is currently charging
bool hal_power_is_charging(void);

#endif
