// Step

if (!form.is_channel) {
	if (--lifetime <= 0 && is_instanceof(form, Form_Rune)) instance_destroy();
}
form.on_step(self);
