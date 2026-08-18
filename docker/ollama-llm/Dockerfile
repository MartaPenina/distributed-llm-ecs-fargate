# generic template — base image and models are set at build time via --build-arg.
# MODEL_NAMES accepts one or more models, space-separated, e.g.:
#   --build-arg MODEL_NAMES="qwen2.5:3b"
#   --build-arg MODEL_NAMES="qwen2.5:3b llama3.1:8b nomic-embed-text:v1.5"
ARG BASE_IMAGE=ollama/ollama:0.3.6
FROM ${BASE_IMAGE}

ARG MODEL_NAMES
EXPOSE 11434

# Starts the Ollama server in the background just for the duration of the
# build (so `ollama pull` has something to talk to), pulls every model in
# the list one by one, then the server is discarded — the models it pulled
# are already saved to disk inside the image layer.
RUN ollama serve & \
    sleep 5 && \
    for model in ${MODEL_NAMES}; do \
        echo "Pulling model: $model" && \
        ollama pull "$model"; \
    done

ENV OLLAMA_HOST=0.0.0.0
CMD ["ollama", "serve"]# trigger test
# retry after IAM fix
