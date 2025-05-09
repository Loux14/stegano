# stegano

A simple bash script for hiding data in images.

![visual](https://github.com/user-attachments/assets/c5cc10b6-ed85-427d-b274-12e4066cdc8b)

## Requirements

- Bash
- ImageMagick

## Usage

![code](https://github.com/user-attachments/assets/505e06cf-6ee6-45ba-bca9-59b8fa3f7cda)

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

![file](https://github.com/user-attachments/assets/b8a464e0-acb2-4ae4-9dfa-c54dacbb3fa2)
