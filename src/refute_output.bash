# Fail and display details if `$output' matches the unexpected output.
# The unexpected output can be specified either by the first parameter
# or on the standard input.
#
# By default, literal matching is performed. The assertion fails if the
# unexpected output equals `$output'. Details include `$output'.
#
# Option `--partial' enables partial matching. The assertion fails if
# the unexpected substring is found in `$output'. The unexpected
# substring is added to details.
#
# Option `--regexp' enables regular expression matching. The assertion
# fails if the extended regular expression does matches `$output'. The
# regular expression is added to details. An invalid regular expression
# causes an error to be displayed.
#
# It is an error to use partial and regular expression matching
# simultaneously.
#
# Globals:
#   output
# Options:
#   -p, --partial - partial matching
#   -e, --regexp - extended regular expression matching
#   -, --stdin - read unexpected output from the standard input
# Arguments:
#   $1 - unexpected output
# Returns:
#   0 - unexpected matches the actual output
#   1 - otherwise
# Inputs:
#   STDIN - [=$1] unexpected output
# Outputs:
#   STDERR - details, on failure
#            error message, on error
refute_output() {
  local -i is_mode_partial=0
  local -i is_mode_regexp=0
  local -i is_mode_empty=0
  local -i use_stdin=0

  # Handle options.
  if (( $# == 0 )); then
    is_mode_empty=1
  fi

  while (( $# > 0 )); do
    case "$1" in
    -p|--partial) is_mode_partial=1; shift ;;
    -e|--regexp) is_mode_regexp=1; shift ;;
    -|--stdin) use_stdin=1; shift ;;
    --) shift; break ;;
    *) break ;;
    esac
  done

  if (( is_mode_partial )) && (( is_mode_regexp )); then
    echo "\`--partial' and \`--regexp' are mutually exclusive" \
    | batslib_decorate 'ERROR: refute_output' \
    | fail
    return $?
  fi

  # Arguments.
  local unexpected
  if (( use_stdin )); then
    unexpected="$(cat -)"
  else
    unexpected="$1"
  fi

  if (( is_mode_regexp == 1 )) && [[ '' =~ $unexpected ]] || (( $? == 2 )); then
    echo "Invalid extended regular expression: \`$unexpected'" \
    | batslib_decorate 'ERROR: refute_output' \
    | fail
    return $?
  fi

  # Matching.
  if (( is_mode_empty )); then
    if [ -n "$output" ]; then
      batslib_print_kv_single_or_multi 6 \
      'output' "$output" \
      | batslib_decorate 'output non-empty, but expected no output' \
      | fail
    fi
  elif (( is_mode_regexp )); then
    if [[ $output =~ $unexpected ]] || (( $? == 0 )); then
      batslib_print_kv_single_or_multi 6 \
      'regexp'  "$unexpected" \
      'output' "$output" \
      | batslib_decorate 'regular expression should not match output' \
      | fail
    fi
  elif (( is_mode_partial )); then
    if [[ $output == *"$unexpected"* ]]; then
      batslib_print_kv_single_or_multi 9 \
      'substring' "$unexpected" \
      'output'    "$output" \
      | batslib_decorate 'output should not contain substring' \
      | fail
    fi
  else
    if [[ $output == "$unexpected" ]]; then
      batslib_print_kv_single_or_multi 6 \
      'output' "$output" \
      | batslib_decorate 'output equals, but it was expected to differ' \
      | fail
    fi
  fi
}
