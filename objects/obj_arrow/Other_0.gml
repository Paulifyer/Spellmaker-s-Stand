/// @description Arrow


// Destroy this arrow
audio_play_sound(choose(snd_impact_archer_01, snd_impact_archer_02, snd_impact_archer_03), 1, false);
instance_destroy(id);
