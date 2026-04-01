#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <alsa/asoundlib.h>

#define SAMPLE_RATE   44100
#define CHANNELS      1
#define PERIOD_FRAMES 1024
#define NUM_PERIODS   3
#define PEAK_CUTOFF   2000

int main(int argc, char **argv) {
    const char *device = (argc > 1) ? argv[1] : "default";
    snd_pcm_t *pcm;
    snd_pcm_hw_params_t *params;
    int err;

    if ((err = snd_pcm_open(&pcm, device, SND_PCM_STREAM_CAPTURE, 0)) < 0) {
        printf("hw_switch:error\n");
        return 1;
    }

    snd_pcm_hw_params_alloca(&params);
    snd_pcm_hw_params_any(pcm, params);
    snd_pcm_hw_params_set_access(pcm, params, SND_PCM_ACCESS_RW_INTERLEAVED);
    snd_pcm_hw_params_set_format(pcm, params, SND_PCM_FORMAT_S16_LE);
    snd_pcm_hw_params_set_channels(pcm, params, CHANNELS);

    unsigned int rate = SAMPLE_RATE;
    snd_pcm_hw_params_set_rate_near(pcm, params, &rate, NULL);

    snd_pcm_uframes_t period = PERIOD_FRAMES;
    snd_pcm_hw_params_set_period_size_near(pcm, params, &period, NULL);

    if ((err = snd_pcm_hw_params(pcm, params)) < 0) {
        snd_pcm_close(pcm);
        printf("hw_switch:error\n");
        return 1;
    }

    int16_t buf[PERIOD_FRAMES * CHANNELS];
    int16_t max_peak = 0;

    for (int p = 0; p < NUM_PERIODS; p++) {
        snd_pcm_sframes_t frames = snd_pcm_readi(pcm, buf, PERIOD_FRAMES);
        if (frames < 0) {
            frames = snd_pcm_recover(pcm, (int)frames, 0);
            if (frames < 0) break;
            p--;
            continue;
        }
        for (snd_pcm_sframes_t i = 0; i < frames * CHANNELS; i++) {
            int16_t v = buf[i] < 0 ? -buf[i] : buf[i];
            if (v > max_peak) max_peak = v;
        }
    }

    snd_pcm_close(pcm);
    printf("hw_switch:%s\n", max_peak >= PEAK_CUTOFF ? "on" : "off");
    return 0;
}
