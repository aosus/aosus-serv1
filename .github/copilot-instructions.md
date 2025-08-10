# AOSUS Server 1 GitOps Repository
AOSUS Server 1 is a GitOps repository managing 11 containerized services for the main AOSUS server including privacy-focused frontends (nitter, redlib, rimgo), search (searxng), Matrix chat (element), and reverse proxy (caddy).

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Setup
- Docker and Docker Compose are required for all operations
- All services use containerized deployments via docker-compose.yml files
- External "web" network must exist: `docker network create web --driver bridge`
- Services expect configuration files in `/home/ubuntu/` on production server (not available in dev)

### Primary Validation Commands
- **CRITICAL**: Always validate any docker-compose changes with these commands:
  ```bash
  # Validate docker-compose syntax (NEVER CANCEL - takes 5-30 seconds)
  docker compose -f path/to/docker-compose.yml config
  
  # Verify images are accessible (NEVER CANCEL - takes 5-60 seconds depending on image size)
  docker compose -f path/to/docker-compose.yml pull
  ```
- **For all files**: Test ALL docker-compose files if making broad changes:
  ```bash
  for file in $(find . -name "docker-compose.yml"); do 
    echo "Testing $file"
    docker compose -f $file config && docker compose -f $file pull
  done
  ```
- **TIMING**: Docker pulls typically take 1-5 seconds per service, but some larger images (simplytranslate) may take 8-12 seconds. Full validation of all 11 services takes 25-35 seconds. Set timeouts to 120+ seconds for safety.

### CI/CD Validation (Required Before PR)
- Run the PR test validation: 
  ```bash
  # This mimics .github/workflows/pr-test.yml
  for file in $(find . -name "docker-compose.yml" -o -name "docker-compose.yaml"); do
    echo "Testing $file"
    docker compose -f $file config 
    docker compose -f $file pull 
  done
  ```
- **NEVER CANCEL** these commands - they must complete for CI to pass

## Service Architecture

### Core Services (11 total)
1. **caddy** - Main reverse proxy and web server (entry point)
2. **element** - Matrix chat client for matrix.aosus.org  
3. **nitter** - Privacy-friendly Twitter frontend
4. **searxng** - Privacy-focused search engine
5. **redlib** - Privacy-friendly Reddit frontend  
6. **quetre** - Privacy-friendly Quora frontend
7. **rimgo** - Privacy-friendly Imgur frontend
8. **scribe** - Privacy-friendly Medium frontend
9. **simplytranslate** - Translation service
10. **sticktock** - Privacy-friendly TikTok frontend
11. **matrix-privacy-link-bot** - Bot for Matrix chat

### Service Dependencies
- All services connect to external "web" network managed by caddy
- Many services use anubis for bot protection
- Several services require redis for caching
- Production configs are mounted from `/home/ubuntu/[service-name]/`

## Deployment Process

### Automatic Deployment
- Each service has individual GitHub workflow in `.github/workflows/[service].yml`
- Triggered on changes to service directory or workflow file
- Uses Tailscale for secure connection to deployment server
- Deploys via docker-compose-gitops-action to remote server
- **NEVER CANCEL** deployment workflows - they include multi-minute operations

### Manual Deployment Testing
- **WARNING**: Services cannot run fully locally due to missing `/home/ubuntu/` configs
- Use `docker compose config` and `docker compose pull` for validation only
- Do NOT attempt `docker compose up` without proper config files

## Common Tasks and Validation

### Adding/Modifying Services
1. Edit or create docker-compose.yml in service directory
2. **ALWAYS** validate with: `docker compose -f path/docker-compose.yml config`
3. **ALWAYS** verify images: `docker compose -f path/docker-compose.yml pull`
4. Create corresponding `.github/workflows/[service].yml` if new service
5. Test all docker-compose files before committing

### Updating Container Images
1. Update image SHA in docker-compose.yml (renovate usually handles this)
2. **CRITICAL**: Always test new image pulls: `docker compose -f service/docker-compose.yml pull`
3. Verify config still validates: `docker compose -f service/docker-compose.yml config`

### Configuration Changes  
1. Update service configuration files in service directory
2. **ALWAYS** validate docker-compose syntax after changes
3. Check that volume mounts and paths are correct
4. Verify environment variables are properly formatted

## Validation Scenarios

### After Making ANY Change
- **MANDATORY**: Run validation commands for affected services
- **MANDATORY**: Test all docker-compose files if making structural changes
- **TIMING**: Full validation takes 25-35 seconds depending on number of services
- **NEVER CANCEL**: Always wait for complete validation before proceeding

### Before Committing
- All docker-compose files must pass `config` validation
- All docker-compose files must pass `pull` validation  
- No syntax errors or warnings (except obsolete version warnings are OK)
- Service dependencies must be correctly defined

### Manual Testing Scenarios
- **Configuration validation**: `docker compose config` succeeds
- **Image availability**: `docker compose pull` succeeds
- **Network connectivity**: External "web" network exists
- **Volume mounts**: Paths exist and are accessible (production only)

## Repository Structure

### Root Directory
```
.
├── .github/
│   └── workflows/        # Individual service deployment workflows
├── README.md            # Basic repository information
├── renovate.json        # Automated dependency updates
├── anubis/             # Bot protection config
├── caddy/              # Main reverse proxy
├── element/            # Matrix chat client  
├── matrix-privacy-link-bot/
├── nitter/             # Twitter frontend
├── quetre/             # Quora frontend
├── redlib/             # Reddit frontend
├── rimgo/              # Imgur frontend
├── scribe/             # Medium frontend
├── searxng/            # Search engine
├── simplytranslate/    # Translation service
└── sticktock/          # TikTok frontend
```

### Service Directory Pattern
Each service directory contains:
- `docker-compose.yml` - Service definition
- Configuration files (settings.yml, config.json, etc.)
- Static assets (logos, favicons, etc.)

## Critical Warnings and Timeouts

### NEVER CANCEL Commands
- `docker compose pull` - Takes 5-60 seconds, may appear to hang
- `docker compose config` - Takes 5-30 seconds  
- GitHub workflow deployments - Take 2-10 minutes
- Set timeouts to 120+ seconds minimum for docker commands

### Common Issues
- **"version is obsolete" warnings**: Safe to ignore, Docker Compose v2 behavior
- **Missing /home/ubuntu/ paths**: Expected in dev environment, services need production configs
- **External network errors**: Run `docker network create web --driver bridge`
- **Permission errors**: Services use specific user IDs (1000:1000) in production
- **"manifest not found" errors**: Some images may be temporarily unavailable (e.g. quetre). Document these in commits when found.

## Quick Reference Commands

```bash
# Validate single service
docker compose -f service/docker-compose.yml config
docker compose -f service/docker-compose.yml pull

# Validate all services with error handling (NEVER CANCEL - takes 1-3 minutes)
for file in $(find . -name "docker-compose.yml"); do 
  echo "Testing $file"
  if docker compose -f $file config > /dev/null 2>&1; then
    echo "✓ Config OK"
    if docker compose -f $file pull > /dev/null 2>&1; then
      echo "✓ $file fully validated"
    else
      echo "⚠ $file config OK but pull failed (may need updated image)"
    fi
  else
    echo "✗ $file config validation failed"
  fi
done

# Simple validation (exits on first failure)
for file in $(find . -name "docker-compose.yml"); do 
  echo "Testing $file" && docker compose -f $file config && docker compose -f $file pull
done

# Create required network
docker network create web --driver bridge

# Check service status (production server only)  
docker compose -f service/docker-compose.yml ps

# View service logs (production server only)
docker compose -f service/docker-compose.yml logs
```

Remember: Always validate docker-compose files before any commit. The CI will fail if any service fails config or pull validation.