#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
show_help() {
    echo -e "${BLUE}Stegano${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 hide [source_image] [text_message] [output_image]"
    echo "  $0 hide -f [source_image] [file_to_hide] [output_image]"
    echo "  $0 extract [image_with_message] [output_file]"
    echo ""
    echo "Examples:"
    echo "  $0 hide image.png \"secret message\" secret_image.png"
    echo "  $0 hide -f image.png document.pdf secret_image.png"
    echo "  $0 extract secret_image.png extracted_message.txt"
    echo ""
    exit 1
}

# Check dependencies
check_dependencies() {
    commands=("identify")
    missing=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies${NC}"
        echo "Please install the following packages:"
        for m in "${missing[@]}"; do
            case "$m" in
                identify) echo "  - ImageMagick" ;;
                *) echo "  - $m" ;;
            esac
        done
        exit 1
    fi
}

# Hide a message in an image
hide_message() {
    local source_image="$1"
    local message="$2"
    local output_image="$3"
    
    # Validate source image
    if [ ! -f "$source_image" ]; then
        echo -e "${RED}Error: Source image does not exist${NC}"
        exit 1
    fi
    
    # Check if source valid
    if ! identify "$source_image" &> /dev/null; then
        echo -e "${RED}Error: '$source_image' is not a valid image${NC}"
        exit 1
    fi
    
    # Message size
    local message_size=${#message}
    
    # Temporary file
    local temp_file=$(mktemp)
    printf "SIZE=%010d\n%s" "$message_size" "$message" > "$temp_file"
    
    # Copy source to output
    cp "$source_image" "$output_image"
    
    # Append data to the end of PNG file
    # Safe because PNG readers ignore data after the IEND chunk
    echo "STEGBASH_DATA_FOLLOWS" >> "$output_image"
    cat "$temp_file" >> "$output_image"
    
    echo -e "${GREEN}Message successfully hidden in '$output_image'${NC}"
    
    # Cleanup
    rm "$temp_file"
}

# Hide a file in an image
hide_file() {
    local source_image="$1"
    local input_file="$2"
    local output_image="$3"
    
    # Validate source files
    if [ ! -f "$source_image" ]; then
        echo -e "${RED}Error: Source image does not exist${NC}"
        exit 1
    fi
    
    if [ ! -f "$input_file" ]; then
        echo -e "${RED}Error: File to hide does not exist${NC}"
        exit 1
    fi
    
    # Check if valid image
    if ! identify "$source_image" &> /dev/null; then
        echo -e "${RED}Error: '$source_image' is not a valid image${NC}"
        exit 1
    fi
    
    # Temporary file
    local temp_file=$(mktemp)
    local file_size=$(wc -c < "$input_file")
    local file_name=$(basename "$input_file")
    
    printf "FILE=%s\nSIZE=%010d\n" "$file_name" "$file_size" > "$temp_file"
    cat "$input_file" >> "$temp_file"
    
    # Copy source to output
    cp "$source_image" "$output_image"
    
    # Append data to end of file
    echo "STEGBASH_DATA_FOLLOWS" >> "$output_image"
    cat "$temp_file" >> "$output_image"
    
    echo -e "${GREEN}File '$file_name' successfully hidden in '$output_image'${NC}"
    
    # Cleanup
    rm "$temp_file"
}

# Extract hidden
extract_data() {
    local stego_image="$1"
    local output_file="$2"
    
    # Validate input
    if [ ! -f "$stego_image" ]; then
        echo -e "${RED}Error: Image does not exist${NC}"
        exit 1
    fi
    
    # Check hidden data
    if grep -q "STEGBASH_DATA_FOLLOWS" "$stego_image"; then
        local marker_pos=$(grep -abo "STEGBASH_DATA_FOLLOWS" "$stego_image" | cut -d: -f1)
        local start_pos=$((marker_pos + 22)) # Length of marker + newline
        
        # Extract after the marker
        tail -c +$start_pos "$stego_image" > "$output_file"
        
        # Detect if file or message
        if grep -q "^FILE=" "$output_file"; then
            local file_name=$(grep "^FILE=" "$output_file" | cut -d= -f2)
            local size_line=$(grep "^SIZE=" "$output_file" | head -1)
            
            # Create new file
            local header_size=$(grep -n "^SIZE=" "$output_file" | head -1 | cut -d: -f1)
            local header_size=$((header_size + $(echo "$size_line" | wc -c) - 1))
            
            # Extract data
            tail -c +$((header_size+1)) "$output_file" > "$file_name"
            rm "$output_file"
            
            echo -e "${GREEN}Successfully extracted file '$file_name'${NC}"
        else
            # Extract message
            local size_line=$(grep "^SIZE=" "$output_file" | head -1)
            
            local header_size=$(grep -n "^SIZE=" "$output_file" | head -1 | cut -d: -f1)
            local header_size=$((header_size + $(echo "$size_line" | wc -c) - 1))
            
            # Extract and save
            tail -c +$((header_size+1)) "$output_file" > "$output_file.tmp"
            mv "$output_file.tmp" "$output_file"
            
            echo -e "${GREEN}Successfully extracted message to '$output_file'${NC}"
        fi
    else
        echo -e "${RED}No hidden data found in the image${NC}"
        rm -f "$output_file"
        exit 1
    fi
}

# Main
main() {

    check_dependencies

    if [ $# -lt 2 ]; then
        show_help
    fi
    
    case "$1" in
        hide)
            if [ "$2" = "-f" ]; then
                if [ $# -ne 5 ]; then
                    show_help
                fi
                hide_file "$3" "$4" "$5"
            else
                if [ $# -ne 4 ]; then
                    show_help
                fi
                hide_message "$2" "$3" "$4"
            fi
            ;;
        extract)
            if [ $# -ne 3 ]; then
                show_help
            fi
            extract_data "$2" "$3"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
}

# Main
main "$@"
