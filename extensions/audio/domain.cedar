// audio domain

@id("audio.op.transcribe")
permit (principal, action == Action::"transcribe", resource)
when { context.domain == "audio" };

@id("audio.op.classify_audio")
permit (principal, action == Action::"classify_audio", resource)
when { context.domain == "audio" };
