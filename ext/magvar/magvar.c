#include <ruby.h>
#include <math.h>
#include "coremag.hxx"

// lat/lon:: decimal degrees (S and W are negative)
// alt:: altitude above sea level in km
// jd:: Julian date
// Returns a two-element array, [var, dip] (radians)
static VALUE vardip(double lat, double lon, double alt, long jd)
{
    double field[6];
    double var = calc_magvar(lat, lon, alt, jd, field);
    double dip = atan(field[5]/sqrt(field[3]*field[3]+field[4]*field[4]));
    return rb_ary_new3(2, rb_float_new(var), rb_float_new(dip));
}

void Init_magvar() {
    VALUE mod;
    mod = rb_define_module("MagVar");
    rb_define_module_function(mod, "vardip", vardip, 4);
}
