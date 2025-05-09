# stegano

A simple bash script for hiding data in images.

## Requirements

- Bash
- ImageMagick

## Usage

### Hide text
```
./stegano.sh hide input.jpg "Enigma message" output.jpg
```

### Extract hidden data
```
./stegano.sh extract output.jpg message.txt
```

## Quick Start

1. Make the script executable:
   ```
   chmod +x stegano.sh
   ```

2. Run with the help flag to see all options:
   ```
   ./stegano.sh help
   ```
