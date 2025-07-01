# EXIFLINT Project

## Overview
`exiflint` is a high-performance bash script that scans images for EXIF GPS metadata that could be personally identifiable. It's designed for CI/CD pipelines and automated website builds to detect potentially sensitive location data in images.

## Key Features
- **Performance optimized**: 13.3x faster than original implementation (4.4s → 0.33s for 42 images)
- **Batch processing**: Uses single `exiftool` calls instead of per-file processing
- **Robust filename handling**: Supports spaces, colons, quotes, and special characters
- **Comprehensive format support**: JPEG, TIFF, PNG, WEBP, HEIC/HEIF, RAW camera files
- **Production ready**: Handles real-world edge cases and arbitrary filenames

## Usage
```bash
./exiflint [-r] [-v] [files/directories...]

Options:
  -r    Recursively search directories
  -v    Verbose output (show each file checked)
  -h    Show help

Exit codes:
  0     No GPS data found
  1     GPS data found in one or more images  
  2     Invalid parameters or execution error
```

## Implementation Details

### Performance Architecture
- **Batch file detection**: Single `file` command call for all files using custom separator (`|||`)
- **Batch EXIF processing**: Single `exiftool -GPS:all` call for all images
- **Null-terminated strings**: Uses `printf '%s\0'` and `xargs -0` for safe filename handling
- **Smart filtering**: Non-images filtered out before expensive EXIF processing

### GPS Tags Checked
Comprehensively checks for all GPS EXIF tags including:
- Core location: GPSLatitude, GPSLongitude, GPSAltitude
- Movement data: GPSSpeed, GPSTrack, GPSBearing
- Timestamps: GPSTimeStamp, GPSDateStamp
- Technical data: GPSDOP, GPSProcessingMethod, GPSAreaInformation
- And 20+ additional GPS-related tags

### Edge Cases Handled
- **Filenames with spaces**: `/path/to/image with spaces.jpg`
- **Filenames with colons**: `/path/to/image:with:colons.jpg`
- **Filenames with quotes**: `/path/to/image"with"quotes.jpg`
- **Single vs multiple files**: Different exiftool output parsing logic
- **Corrupted files**: Gracefully skips unreadable/non-image files
- **Permission issues**: Handles files with restricted access

## Testing

### Test Structure
```
tests/
├── has_gps_data.jpg           # Image with GPS metadata (iPhone photo)
├── no_gps_data.jpg            # Clean image without GPS data
├── test_exiflint.bats         # Main functionality tests (18 tests)
└── test_edge_cases.bats       # Edge case tests (10 tests)
```

### Running Tests
```bash
cd tests
bats test_exiflint.bats      # Main functionality 
bats test_edge_cases.bats    # Edge cases
bats test_*.bats             # All tests (28 total)
```

### Test Coverage
- Basic functionality (GPS detection, exit codes, options)
- Command line argument validation
- Verbose vs quiet output modes
- Directory processing (recursive and non-recursive)
- File type detection and filtering
- Special character filename handling
- Batch processing boundary conditions
- Error handling and edge cases

## Development Notes

### Dependencies
- `exiftool` - EXIF metadata extraction
- `file` - File type detection
- `bash` 4.0+ - For regex and array features
- Standard UNIX utilities: `find`, `xargs`, `mktemp`

### Performance Insights
- **Fork overhead is massive**: 93% of original time was process forking
- **Batch processing wins**: Single calls are 10-15x faster than individual calls
- **File command is fast**: ~180x faster than exiftool for type detection
- **Memory efficient**: Uses temp files instead of large arrays for file lists

### Known Limitations
- Requires `exiftool` to be installed
- May not detect GPS data in proprietary RAW formats without proper exiftool plugins
- Uses `|||` as separator (could theoretically conflict with very unusual filenames)

## Git History
- Initial implementation with per-file processing
- Performance optimization with batch processing (13x speedup)
- Edge case fixes for special character filenames
- Comprehensive test suite development
- Code organization and cleanup

## Build/CI Integration
Designed to run on every website build without special configuration:
```bash
# Example CI usage
./exiflint -r src/images/
if [ $? -eq 1 ]; then
  echo "ERROR: Images contain GPS metadata"
  exit 1
fi
```

The script is fast enough to run on large websites without requiring pre-filtering or special handling of file types.