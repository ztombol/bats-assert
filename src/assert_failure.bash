# Fail and display details if `$status' is 0. Details include `$output'.
#
# Optionally, when the expected status is specified, fail when it does
# not equal `$status'. In this case, details include the expected and
# actual status, and `$output'.
#
# Globals:
#   status
#   output
# Arguments:
#   $1 - [opt] expected status
# Returns:
#   0 - `$status' is not 0, or
#       `$status' equals the expected status
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_failure() {
  (( $# > 0 )) && local -r expected="$1"
  if (( status == 0 )); then
    batslib_print_kv_single_or_multi 6 'output' "$output" \
    | batslib_decorate 'command succeeded, but it was expected to fail' \
    | fail
  elif (( $# > 0 )) && (( status != expected )); then
    { local -ir width=8
      batslib_print_kv_single "$width" \
      'expected' "$expected" \
      'actual'   "$status"
      batslib_print_kv_single_or_multi "$width" \
      'output' "$output"
    } \
    | batslib_decorate 'command failed as expected, but status differs' \
    | fail
  fi
}
