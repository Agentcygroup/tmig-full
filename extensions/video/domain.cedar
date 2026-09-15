// video domain

@id("video.op.decode")
permit (principal, action == Action::"decode", resource)
when { context.domain == "video" };

@id("video.op.track")
permit (principal, action == Action::"track", resource)
when { context.domain == "video" };
