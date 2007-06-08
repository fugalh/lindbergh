#include <ruby.h>
#include <math.h>
#include "coremag.hxx"

/* lat/lon:: decimal radians (S and W are negative)
 * alt:: altitude above sea level in km
 * jd:: Julian date
 * Returns a two-element array, [var, dip] (radians)
 */
static VALUE vardip(VALUE self, VALUE lat, VALUE lon, VALUE alt, VALUE jd)
{
    double clat = NUM2DBL(lat);
    double clon = NUM2DBL(lon);
    double calt = NUM2DBL(alt);
    long   cjd  = NUM2LONG(jd);

    double field[6];
    double var = calc_magvar(clat, clon, calt, cjd, field);
    double dip = atan(field[5]/sqrt(field[3]*field[3]+field[4]*field[4]));

    return rb_ary_new3(2, rb_float_new(var), rb_float_new(dip));
}

/* Magnetic variation calculation, using the code from SimGear
 */
void Init_magvar() {
    VALUE flan, mod;
    flan = rb_define_module("Aviation");
    mod = rb_define_module_under(flan, "MagVar");
    rb_define_module_function(mod, "c_vardip", vardip, 4);
}
