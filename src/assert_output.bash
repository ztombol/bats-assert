# Fail and display details if `$output' does not match the expected
# output. The expected output can be specified either by the first
# parameter or on the standard input.
#
# By default, literal matching is performed. The assertion fails if the
# expected output does not equal `$output'. Details include both values.
#
# Option `--partial' enables partial matching. The assertion fails if
# the expected substring cannot be found in `$output'.
#
# Option `--regexp' enables regular expression matching. The assertion
# fails if the extended regular expression does not match `$output'. An
# invalid regular expression causes an error to be displayed.
#
# It is an error to use partial and regular expression matching
# simultaneously.
#
# Globals:
#   output
# Options:
#   -p, --partial - partial matching
#   -e, --regexp - extended regular expression matching
#   -, --stdin - read expected output from the standard input
# Arguments:
#   $1 - expected output
# Returns:
#   0 - expected matches the actual output
#   1 - otherwise
# Inputs:
#   STDIN - [=$1] expected output
# Outputs:
#   STDERR - details, on failure
#            error message, on error
assert_output() {
  local -i is_mode_partial=0
  local -i is_mode_regexp=0
  local -i is_mode_nonempty=0
  local -i use_stdin=0
  : "${output?}"

  # Handle options.
  if (( $# == 0 )); then
    is_mode_nonempty=1
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
    | batslib_decorate 'ERROR: assert_output' \
    | fail
    return $?
  fi

  # Arguments.
  local expected
  if (( use_stdin )); then
    expected="$(cat -)"
  else
    expected="${1-}"
  fi

  # Matching.
  if (( is_mode_nonempty )); then
    if [ -z "$output" ]; then
      echo 'expected non-empty output, but output was empty' \
      | batslib_decorate 'no output' \
      | fail
    fi
  elif (( is_mode_regexp )); then
    if [[ '' =~ $expected ]] || (( $? == 2 )); then
      echo "Invalid extended regular expression: \`$expected'" \
      | batslib_decorate 'ERROR: assert_output' \
      | fail
    elif ! [[ $output =~ $expected ]]; then
      batslib_print_kv_single_or_multi 6 \
      'regexp'  "$expected" \
      'output' "$output" \
      | batslib_decorate 'regular expression does not match output' \
      | fail
    fi
  elif (( is_mode_partial )); then
    if [[ $output != *"$expected"* ]]; then
      batslib_print_kv_single_or_multi 9 \
      'substring' "$expected" \
      'output'    "$output" \
      | batslib_decorate 'output does not contain substring' \
      | fail
    fi
  else
    if [[ $output != "$expected" ]]; then
      batslib_print_kv_single_or_multi 8 \
      'expected' "$expected" \
      'actual'   "$output" \
      | batslib_decorate 'output differs' \
      | fail
    fi
  fi
}
