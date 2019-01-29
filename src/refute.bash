# Fail and display the expression if it evaluates to true.
#
# NOTE: The expression must be a simple command. Compound commands, such
#       as `[[', can be used only when executed with `bash -c'.
#
# Globals:
#   none
# Arguments:
#   $1 - expression
# Returns:
#   0 - expression evaluates to FALSE
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
refute() {
  if "$@"; then
    batslib_print_kv_single 10 'expression' "$*" \
    | batslib_decorate 'assertion succeeded, but it was expected to fail' \
    | fail
  fi
}
