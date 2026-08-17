# Search

```bash
export TAKO_API_KEY="sk-..."
./scripts/tako-search.sh "What is the capital of Japan?" --count 3
```

# Image

```bash
./scripts/tako-image.sh generate "a corgi on Mars" --model gpt-image-2
```

# Speech

```bash
./scripts/tako-speech.sh tts "你好，这是语音合成测试" --out ./hello.wav
./scripts/tako-speech.sh asr ./hello.wav
```

# Video

```bash
./scripts/tako-video.sh create "a calico cat playing piano"
./scripts/tako-video.sh status "$TASK_ID"
./scripts/tako-video.sh download "$TASK_ID" --out ./out.mp4
```
