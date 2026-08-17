# Search — capital of Japan

```bash
export TAKO_API_KEY="sk-..."
./scripts/tako-search.sh "What is the capital of Japan?" --count 3
```

Expected shape:

```json
{
  "query": "What is the capital of Japan?",
  "provider": "kab",
  "answer": "optional",
  "results": [
    {
      "title": "Capital of Japan",
      "url": "https://en.wikipedia.org/wiki/Capital_of_Japan",
      "snippet": "..."
    }
  ]
}
```

# Image — generate

```bash
./scripts/tako-image.sh generate "a corgi on Mars" --model gpt-image-2
```

Expected shape:

```json
{
  "created": 1710000000,
  "data": [
    {"url": "https://..."}
  ]
}
```
