#!/usr/bin/env bats

# Bats tests for exiflint script

setup() {
    # Set up test environment
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/exiflint"
    export TEST_DIR="$BATS_TEST_DIRNAME/tests"
    export GPS_IMAGE="$TEST_DIR/has_gps_data.jpg"
    export CLEAN_IMAGE="$TEST_DIR/no_gps_data.jpg"
    
    # Verify test files exist
    [ -f "$SCRIPT_PATH" ]
    [ -f "$GPS_IMAGE" ]
    [ -f "$CLEAN_IMAGE" ]
}

@test "script exists and is executable" {
    [ -x "$SCRIPT_PATH" ]
}

@test "shows help with -h flag" {
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Exit codes:" ]]
}

@test "fails with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Error: No files or directories specified" ]]
}

@test "fails with non-existent file" {
    run "$SCRIPT_PATH" /nonexistent/file.jpg
    [ "$status" -eq 2 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "detects GPS data in image (exit code 1)" {
    run "$SCRIPT_PATH" "$GPS_IMAGE"
    [ "$status" -eq 1 ]
    [[ "$output" == "$GPS_IMAGE" ]]
}

@test "passes clean image (exit code 0)" {
    run "$SCRIPT_PATH" "$CLEAN_IMAGE"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "verbose mode shows PASS for clean image" {
    run "$SCRIPT_PATH" -v "$CLEAN_IMAGE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ": PASS" ]]
}

@test "verbose mode shows FAIL for GPS image" {
    run "$SCRIPT_PATH" -v "$GPS_IMAGE"
    [ "$status" -eq 1 ]
    [[ "$output" =~ ": FAIL" ]]
}

@test "processes multiple files" {
    run "$SCRIPT_PATH" "$GPS_IMAGE" "$CLEAN_IMAGE"
    [ "$status" -eq 1 ]
    [[ "$output" == "$GPS_IMAGE" ]]
}

@test "verbose mode with multiple files" {
    run "$SCRIPT_PATH" -v "$GPS_IMAGE" "$CLEAN_IMAGE"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "$GPS_IMAGE: FAIL" ]]
    [[ "$output" =~ "$CLEAN_IMAGE: PASS" ]]
}

@test "processes directory without recursion" {
    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "$GPS_IMAGE" ]]
}

@test "processes directory with recursion flag" {
    run "$SCRIPT_PATH" -r "$TEST_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "$GPS_IMAGE" ]]
}

@test "verbose directory processing" {
    run "$SCRIPT_PATH" -v "$TEST_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ ": FAIL" ]]
    [[ "$output" =~ ": PASS" ]]
}

@test "combined flags work correctly" {
    run "$SCRIPT_PATH" -rv "$TEST_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ ": FAIL" ]]
    [[ "$output" =~ ": PASS" ]]
}

@test "invalid flag shows error" {
    run "$SCRIPT_PATH" -x
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Invalid option" ]]
}

@test "requires exiftool dependency" {
    # Temporarily rename exiftool to test dependency check
    if command -v exiftool &> /dev/null; then
        # Test that script would fail if exiftool missing
        # We can't actually test this without breaking the system
        skip "Cannot test missing exiftool without breaking system"
    else
        run "$SCRIPT_PATH" "$CLEAN_IMAGE"
        [ "$status" -eq 2 ]
        [[ "$output" =~ "exiftool is required" ]]
    fi
}

@test "handles non-image files gracefully" {
    # Create a temporary non-image file
    echo "not an image" > "$BATS_TMPDIR/test.txt"
    
    run "$SCRIPT_PATH" "$BATS_TMPDIR/test.txt"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    
    # Clean up
    rm "$BATS_TMPDIR/test.txt"
}

@test "verbose mode shows only images checked" {
    # Create a temporary non-image file
    echo "not an image" > "$BATS_TMPDIR/test.txt"
    
    run "$SCRIPT_PATH" -v "$BATS_TMPDIR/test.txt" "$CLEAN_IMAGE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$CLEAN_IMAGE: PASS" ]]
    [[ ! "$output" =~ "test.txt" ]]
    
    # Clean up
    rm "$BATS_TMPDIR/test.txt"
}