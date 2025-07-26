#!/usr/bin/env bats

# Additional edge case tests for batch processing version

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../geolint"
    export TEST_DIR="$BATS_TEST_DIRNAME"
    export GPS_IMAGE="$TEST_DIR/has_gps_data.jpg"
    export CLEAN_IMAGE="$TEST_DIR/no_gps_data.jpg"
    
    # Create temp directory for edge case test files
    export EDGE_TEST_DIR="$BATS_TMPDIR/edge_tests"
    mkdir -p "$EDGE_TEST_DIR"
}

teardown() {
    # Clean up edge test files
    rm -rf "$EDGE_TEST_DIR" 2>/dev/null || true
}

@test "handles filenames with spaces" {
    # Create file with spaces in name
    local spaced_file="$EDGE_TEST_DIR/image with spaces.jpg"
    cp "$CLEAN_IMAGE" "$spaced_file"
    
    run "$SCRIPT_PATH" -v "$spaced_file"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "PASS" ]]
}

@test "handles filenames with colons" {
    # Create file with colons in name  
    local colon_file="$EDGE_TEST_DIR/image:with:colons.jpg"
    cp "$GPS_IMAGE" "$colon_file"
    
    run "$SCRIPT_PATH" "$colon_file"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "$colon_file" ]]
}

@test "handles filenames with quotes" {
    # Create file with quotes in name
    local quote_file="$EDGE_TEST_DIR/image\"with\"quotes.jpg"
    cp "$CLEAN_IMAGE" "$quote_file"
    
    run "$SCRIPT_PATH" -v "$quote_file"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "PASS" ]]
}

@test "boundary condition: exactly 2 files (single vs multiple logic)" {
    # Test the transition from single-file to multi-file processing
    run "$SCRIPT_PATH" -v "$GPS_IMAGE" "$CLEAN_IMAGE"
    [ "$status" -eq 1 ]
    [[ "$output" =~ ": FAIL" ]]
    [[ "$output" =~ ": PASS" ]]
    
    # Should be same result as processing individually
    run "$SCRIPT_PATH" "$GPS_IMAGE"
    [ "$status" -eq 1 ]
    
    run "$SCRIPT_PATH" "$CLEAN_IMAGE"
    [ "$status" -eq 0 ]
}

@test "handles corrupted file in batch gracefully" {
    # Create a corrupted "image" file
    local corrupt_file="$EDGE_TEST_DIR/corrupted.jpg"
    echo "This is not a real JPEG file" > "$corrupt_file"
    
    # Should still process the real image correctly
    run "$SCRIPT_PATH" -v "$corrupt_file" "$CLEAN_IMAGE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$CLEAN_IMAGE: PASS" ]]
    # Corrupted file should not appear in output (not detected as image)
    [[ ! "$output" =~ "$corrupt_file" ]]
}

@test "handles unreadable file permissions" {
    # Create file then remove read permissions
    local no_read_file="$EDGE_TEST_DIR/no_read.jpg"
    cp "$CLEAN_IMAGE" "$no_read_file"
    chmod 000 "$no_read_file"
    
    # Should handle gracefully without crashing
    run "$SCRIPT_PATH" "$no_read_file" "$CLEAN_IMAGE"
    [ "$status" -eq 0 ]
    
    # Clean up (restore permissions for cleanup)
    chmod 644 "$no_read_file" 2>/dev/null || true
}

@test "processes large batch efficiently" {
    # Create a larger batch to test performance doesn't degrade badly
    local batch_files=()
    for i in {1..10}; do
        local test_file="$EDGE_TEST_DIR/batch_test_$i.jpg"
        if (( i % 2 == 0 )); then
            cp "$GPS_IMAGE" "$test_file"
            batch_files+=("$test_file")
        else
            cp "$CLEAN_IMAGE" "$test_file"
        fi
    done
    
    run "$SCRIPT_PATH" -r "$EDGE_TEST_DIR"
    [ "$status" -eq 1 ]
    
    # Should find exactly 5 files with GPS data
    local failed_count=$(echo "$output" | wc -l)
    [ "$failed_count" -eq 5 ]
}

@test "handles mixed file types in directory" {
    # Create directory with images and non-images
    cp "$GPS_IMAGE" "$EDGE_TEST_DIR/gps.jpg"
    cp "$CLEAN_IMAGE" "$EDGE_TEST_DIR/clean.jpg"
    echo "text file" > "$EDGE_TEST_DIR/readme.txt"
    echo "#!/bin/bash" > "$EDGE_TEST_DIR/script.sh"
    mkdir -p "$EDGE_TEST_DIR/subdir"
    
    run "$SCRIPT_PATH" -rv "$EDGE_TEST_DIR"
    [ "$status" -eq 1 ]
    
    # Should only process image files
    [[ "$output" =~ "gps.jpg: FAIL" ]]
    [[ "$output" =~ "clean.jpg: PASS" ]]
    [[ ! "$output" =~ "readme.txt" ]]
    [[ ! "$output" =~ "script.sh" ]]
}

@test "handles empty directory gracefully" {
    local empty_dir="$EDGE_TEST_DIR/empty"
    mkdir -p "$empty_dir"
    
    run "$SCRIPT_PATH" -r "$empty_dir"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "preserves file order consistency" {
    # Create files and test that batch processing gives consistent results
    local file1="$EDGE_TEST_DIR/a_clean.jpg"
    local file2="$EDGE_TEST_DIR/b_gps.jpg"
    local file3="$EDGE_TEST_DIR/c_clean.jpg"
    
    cp "$CLEAN_IMAGE" "$file1"
    cp "$GPS_IMAGE" "$file2"
    cp "$CLEAN_IMAGE" "$file3"
    
    # Test multiple times to ensure consistency
    run "$SCRIPT_PATH" "$file1" "$file2" "$file3"
    local output1="$output"
    [ "$status" -eq 1 ]
    
    run "$SCRIPT_PATH" "$file1" "$file2" "$file3"
    local output2="$output"
    [ "$status" -eq 1 ]
    
    # Should be identical results
    [ "$output1" = "$output2" ]
}

@test "directory without -r flag should return exit code 2" {
    # Create directory with images
    local test_dir="$EDGE_TEST_DIR/no_recursive"
    mkdir -p "$test_dir"
    cp "$GPS_IMAGE" "$test_dir/gps.jpg"
    cp "$CLEAN_IMAGE" "$test_dir/clean.jpg"
    
    # Should fail with exit code 2 (invalid parameters)
    run "$SCRIPT_PATH" "$test_dir"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Error:" ]]
    [[ "$output" =~ "directory" ]]
    [[ "$output" =~ "-r" ]]
}

@test "multiple directories without -r flag should return exit code 2" {
    # Create multiple directories
    local test_dir1="$EDGE_TEST_DIR/no_recursive1"
    local test_dir2="$EDGE_TEST_DIR/no_recursive2"
    mkdir -p "$test_dir1" "$test_dir2"
    cp "$GPS_IMAGE" "$test_dir1/gps.jpg"
    cp "$CLEAN_IMAGE" "$test_dir2/clean.jpg"
    
    # Should fail with exit code 2 even if only one directory is present
    run "$SCRIPT_PATH" "$test_dir1" "$test_dir2"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Error:" ]]
    [[ "$output" =~ "directory" ]]
    [[ "$output" =~ "-r" ]]
}

@test "mixed files and directories without -r flag should return exit code 2" {
    # Create a directory and use a file
    local test_dir="$EDGE_TEST_DIR/mixed_test"
    mkdir -p "$test_dir"
    cp "$GPS_IMAGE" "$test_dir/gps.jpg"
    
    # Should fail with exit code 2 because of the directory argument
    run "$SCRIPT_PATH" "$CLEAN_IMAGE" "$test_dir"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Error:" ]]
    [[ "$output" =~ "directory" ]]
    [[ "$output" =~ "-r" ]]
}

@test "directory with -r flag should work normally" {
    # Create directory with images
    local test_dir="$EDGE_TEST_DIR/with_recursive"
    mkdir -p "$test_dir"
    cp "$GPS_IMAGE" "$test_dir/gps.jpg"
    cp "$CLEAN_IMAGE" "$test_dir/clean.jpg"
    
    # Should work normally with -r flag
    run "$SCRIPT_PATH" -r "$test_dir"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "gps.jpg" ]]
}

@test "glob expansion processes individual files without -r flag" {
    # Create directory with images
    local test_dir="$EDGE_TEST_DIR/glob_test"
    mkdir -p "$test_dir"
    cp "$GPS_IMAGE" "$test_dir/gps.jpg"
    cp "$CLEAN_IMAGE" "$test_dir/clean.jpg"
    echo "text file" > "$test_dir/readme.txt"
    
    # Glob expansion should work without -r since it expands to individual files
    run bash -c "cd '$test_dir' && '$SCRIPT_PATH' -v *"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "gps.jpg: FAIL" ]]
    [[ "$output" =~ "clean.jpg: PASS" ]]
    # Should not process non-image files
    [[ ! "$output" =~ "readme.txt" ]]
}