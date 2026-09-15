package sovereign
default allow = false
allow {
    input.jurisdiction in ["US","EU","GB","JP","KR","IN","BR","DE","FR","CA","AU"]
    input.task in ["text-generation","translation","summarization",
                   "text-classification","question-answering",
                   "automatic-speech-recognition","text-to-speech"]
}
deny[msg] {
    input.task == "text-to-image"
    input.model_class == "unfiltered"
    msg := "unfiltered image generation requires explicit opt-in"
}
