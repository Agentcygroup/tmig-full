// diffusion domain

@id("diffusion.op.denoise")
permit (principal, action == Action::"denoise", resource)
when { context.domain == "diffusion" };

@id("diffusion.op.generate_image")
permit (principal, action == Action::"generate_image", resource)
when { context.domain == "diffusion" };
