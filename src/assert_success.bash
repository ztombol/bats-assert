# Fail and display details if `$status' is not 0. Details include
# `$status' and `$output'.
#
# Globals:
#   status
#   output
# Arguments:
#   none
# Returns:
#   0 - `$status' is 0
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_success() {
  if (( status != 0 )); then
    { local -ir width=6
      batslib_print_kv_single "$width" 'status' "$status"
      batslib_print_kv_single_or_multi "$width" 'output' "$output"
    } | batslib_decorate 'command failed' \
      | fail
  fi
}
