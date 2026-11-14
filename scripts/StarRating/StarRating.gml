/// @description Validated defaults with optional per-level overrides (percent, not HP).
function level_star_thresholds(_override = undefined) {
    var _two = tune_value("star_rating", "two_star_wall_hp_percent", 33);
    var _three = tune_value("star_rating", "three_star_wall_hp_percent", 66);
    if (is_struct(_override)) {
        if (is_real(_override[$ "two_star_wall_hp_percent"])) _two = _override[$ "two_star_wall_hp_percent"];
        if (is_real(_override[$ "three_star_wall_hp_percent"])) _three = _override[$ "three_star_wall_hp_percent"];
    }
    if (!(_two >= 0 && _two < _three && _three <= 100)) {
        show_debug_message("Invalid star thresholds; using 33 and 66 percent.");
        _two = 33;
        _three = 66;
    }
    return {two: _two, three: _three};
}

function level_star_result(_completed, _hp, _max_hp, _damaged, _thresholds) {
    var _percent = _max_hp > 0 ? clamp(_hp / _max_hp * 100, 0, 100) : 0;
    var _stars = 0;
    var _flawless = false;
    if (_completed && _hp > 0 && _max_hp > 0) {
        _stars = 1;
        if (_percent > _thresholds.two) _stars = 2;
        if (_percent > _thresholds.three) _stars = 3;
        _flawless = !_damaged;
        if (_flawless) _stars = 3;
    }
    return {stars: _stars, flawless: _flawless, hp_percent: _percent, hp_remaining: max(0, _hp)};
}

/// @description Keep best stars and flawless independently, including across launches.
function save_level_stars(_level, _result) {
    if (_result.stars <= 0) return;
    ini_open("level_stars.ini");
    var _best = clamp(ini_read_real(_level, "stars", 0), 0, 3);
    var _flawless = ini_read_real(_level, "flawless", 0) > 0;
    ini_write_real(_level, "stars", max(_best, _result.stars));
    ini_write_real(_level, "flawless", (_flawless || _result.flawless) ? 1 : 0);
    ini_close();
}

// A contiguous chain of clears unlocks the campaign, starting with level one.
function level_select_progress(_rooms) {
    var _progress = [];
    var _unlocked = true;
    ini_open("level_stars.ini");
    for (var i = 0; i < array_length(_rooms); i++) {
        var _level = room_get_name(_rooms[i]);
        var _stars = clamp(floor(ini_read_real(_level, "stars", 0)), 0, 3);
        var _flawless = ini_read_real(_level, "flawless", 0) > 0;
        array_push(_progress, {unlocked: _unlocked, stars: _stars, flawless: _flawless});
        _unlocked = _unlocked && _stars > 0;
    }
    ini_close();
    return _progress;
}
