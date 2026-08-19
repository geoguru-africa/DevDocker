# GeoServer DevDocker Environment

Containerized GeoServer ecosystem development environment (GeoServer, GeoTools, GeoWebCache).

This README is intentionally short. Detailed content has been split into focused docs.

## Quick Start

```bash
git clone https://github.com/geoguru-africa/DevDocker.git
cd DevDocker
cp .env.example .env
docker compose up -d
ssh -p 2222 root@localhost
```

Inside the container:

```bash
cd /workspace
git clone https://github.com/YOUR_USERNAME/geoserver.git
cd geoserver
build-geoserver.sh
```

## Documentation

### Start here

- [Quick Start](docs/QUICK-START.md)
- [Image Usage (Docker Hub and local builds)](docs/IMAGE-USAGE.md)
- [Source Code Workflow](docs/SOURCE-CODE-WORKFLOW.md)
- [Configuration Reference](docs/CONFIGURATION-REFERENCE.md)

### Development

- [IDE Connectivity](docs/IDE-CONNECTIVITY.md)
- [Remote Debugging](docs/VSCODE-REMOTE-DEBUGGING.md)
- [Maven Fallback Chain](docs/MAVEN-FALLBACK-CHAIN.md)
- [Developer Extensibility](docs/DEVELOPER-EXTENSIBILITY.md)
- [Data Directory](docs/DATA-DIRECTORY.md)

### Troubleshooting

- [Troubleshooting Index](docs/TROUBLESHOOTING.md)
- [Error Handling](docs/ERROR-HANDLING.md)
- [SSH Host Key Verification](docs/SSH-HOST-KEY-VERIFICATION.md)

## Common Questions

### Why am I seeing the wrong Java/Tomcat combination?

Use:

```bash
./scripts/rebuild-container.sh
```

It detects the GeoServer branch and rebuilds with the expected base image.

### Is `docker-compose.override.yml` applied automatically?

Yes. Docker Compose automatically merges `docker-compose.override.yml` when you run plain `docker compose up` in the same directory.

### When should I build locally?

Only when changing DevDocker itself. For normal usage, the default is the pre-built image from Docker Hub.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License.

