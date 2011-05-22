/* -*- c++ -*- */
/*
 * Copyright 2011 Alexandru Csete OZ9AEC.
 *
 * Gqrx is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * Gqrx is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gqrx; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */
#include <gr_io_signature.h>
#include <gr_firdes.h>
#include <rx_demod_fm.h>

#include <iostream>


/* Create a new instance of rx_demod_fm and return a boost shared_ptr. */
rx_demod_fm_sptr make_rx_demod_fm(float quad_rate, float audio_rate, float max_dev, double tau)
{
    return gnuradio::get_initial_sptr(new rx_demod_fm(quad_rate, audio_rate, max_dev, tau));
}


static const int MIN_IN = 1;  /* Mininum number of input streams. */
static const int MAX_IN = 1;  /* Maximum number of input streams. */
static const int MIN_OUT = 1; /* Minimum number of output streams. */
static const int MAX_OUT = 1; /* Maximum number of output streams. */



rx_demod_fm::rx_demod_fm(float quad_rate, float audio_rate, float max_dev, double tau)
    : gr_hier_block2 ("rx_demod_fm",
                      gr_make_io_signature (MIN_IN, MAX_IN, sizeof (gr_complex)),
                      gr_make_io_signature (MIN_OUT, MAX_OUT, sizeof (float))),
    d_quad_rate(quad_rate),
    d_audio_rate(audio_rate),
    d_max_dev(max_dev),
    d_tau(tau)
{
    float gain;

    /* demodulator gain */
    gain = d_quad_rate / (2.0 * M_PI * d_max_dev);

    std::cout << "G: " << gain << std::endl;

    /* demodulator */
    d_quad = gr_make_quadrature_demod_cf(gain);

    /* de-emphasis */
    if (d_tau > 0.0) {
        // FIXME
    }

    /* PFB resampler */
    //d_taps = gr_firdes::low_pass(32.0, 32.0*d_quad_rate, d_quad_rate/2.0, 0.1*d_quad_rate/2.0);
    //d_resampler = gr_make_pfb_arb_resampler_fff (d_audio_rate/d_quad_rate, d_taps, 32);

    /* connect block */
    connect(self(), 0, d_quad, 0);
    connect(d_quad, 0, self(), 0);

}


rx_demod_fm::~rx_demod_fm ()
{

}


void rx_demod_fm::set_max_dev(float max_dev)
{
    // FIXME
}


void rx_demod_fm::set_tau(double tau)
{
    // FIXME
}


