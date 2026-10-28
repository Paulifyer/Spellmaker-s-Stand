///@description Next Level Button

// Inherit the parent event
event_inherited();

// Set the button text
text = global.current_level + 1 < array_length(global.level_array) ? "NEXT LEVEL" : "MENU";

// Set the outline color
text_outline_color = #185017;
