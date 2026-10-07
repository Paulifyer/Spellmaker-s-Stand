// Step

if (!form.is_channel) {
	if (--lifetime <= 0) instance_destroy();
}
form.on_step(self);
