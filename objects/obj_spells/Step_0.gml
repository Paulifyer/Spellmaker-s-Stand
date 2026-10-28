// Step

if (!form.is_channel && lifetime != -1) {
	if (--lifetime <= 0) {
		instance_destroy();
		exit;
	}
}
form.on_step(self);
