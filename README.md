<!-- <div style="display: flex; align-items: center; gap: 1rem;">
  <img src="assets/KRAKEN LOGO (1).png" alt="Kraken-Clean Logo" width="150" />
  <h1>Kraken-Clean</h1>
</div> -->

# Kraken-Clean
> **Kraken-Clean is a lightweight bash utility to clean up docker resoueces based on the configurable prefix. It supports dry-run mode, verbose logging and force removal of resources.**

## Features
- **Clean Docker resources** with the given prefix (default = "test-") 
- **Dry-Run mode** to preview what will be removed.
- **Verbose Logging** to console and to a log file.
- **Force Removal** support for running containers or in-use images. 
- Maintains a log file with timestamps for auditing. 

## How to use? 
```bash
./kraken-clean.sh [options] <command> 
```

### Options
| Option            | Description                                                                        |
| ----------------- | ---------------------------------------------------------------------------------- |
| `-d`, `--dry-run` | Preview what will be removed (no actual deletion)                                  |
| `-p`, `--prefix`  | Set a custom prefix (default: `test-`)                                             |
| `-v`, `--verbose` | Enable verbose logging to console (default: enabled)                               |
| `-f`, `--force`   | Force remove containers (stops them if running) or images (removes even if in use) |
| `-h`, `--help`    | Show help message                                                                  |

### Commands
| Command      | Description                                            |
| ------------ | ------------------------------------------------------ |
| `images`     | Clean Docker images matching the configured prefix     |
| `containers` | Clean Docker containers matching the configured prefix |

## Examples

1. Clean resources with Default prefix 
```bash
./kraken-clean.sh images        # For images
./kraken-clean.sh containers    # For containers
``` 

2. Clean resources with custom prefix
```bash
./kraken-clean.sh -p "random-" images       # For images
./kraken-clean.sh -p "random-" containers   # For containers
```

3. Preview what will be removed
```bash
./kraken-clean.sh -d images         # For images
./kraken-clean.sh -d containers     # For containers 
``` 

4. Force remove resources
```bash
./kraken-clean.sh -f images         # For images
./kraken-clean.sh -f containers     # For containers
``` 

5. You can combine options 
```bash
./kraken-clean.sh -p "random-" -f images        # For images
./kraken-clean.sh -p "random-" -f containers    # For containers
```

## Logs
- All operations are logged in

## Future Upgrades
- make this as a package
- Include more resource deletion. 