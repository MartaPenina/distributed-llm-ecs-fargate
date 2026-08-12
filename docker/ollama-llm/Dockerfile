# generic template — which model and which base image get set at build time via --build-arg
ARG BASE_IMAGE=ollama/ollama:0.3.6
FROM ${BASE_IMAGE}

ARG MODEL_NAME
EXPOSE 11434

RUN ollama serve & \
    sleep 5 && \
    ollama pull ${MODEL_NAME}

ENV OLLAMA_HOST=0.0.0.0
CMD ["ollama", "serve"]