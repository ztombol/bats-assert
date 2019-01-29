# Fail and display details if the expected line is not found in the
# output (default) or in a specific line of it.
#
# By default, the entire output is searched for the expected line. The
# expected line is matched against every element of `${lines[@]}'. If no
# match is found, the assertion fails. Details include the expected line
# and `${lines[@]}'.
#
# When `--index <idx>' is specified, only the <idx>-th line is matched.
# If the expected line does not match `${lines[<idx>]}', the assertion
# fails. Details include <idx> and the compared lines.
#
# By default, literal matching is performed. A literal match fails if
# the expected string does not equal the matched string.
#
# Option `--partial' enables partial matching. A partial match fails if
# the expected substring is not found in the target string.
#
# Option `--regexp' enables regular expression matching. A regular
# expression match fails if the extended regular expression does not
# match the target string. An invalid regular expression causes an error
# to be displayed.
#
# It is an error to use partial and regular expression matching
# simultaneously.
#
# Mandatory arguments to long options are mandatory for short options
# too.
#
# Globals:
#   output
#   lines
# Options:
#   -n, --index <idx> - match the <idx>-th line
#   -p, --partial - partial matching
#   -e, --regexp - extended regular expression matching
# Arguments:
#   $1 - expected line
# Returns:
#   0 - match found
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
#            error message, on error
# FIXME(ztombol): Display `${lines[@]}' instead of `$output'!
assert_line() {
  local -i is_match_line=0
  local -i is_mode_partial=0
  local -i is_mode_regexp=0

  # Handle options.
  while (( $# > 0 )); do
    case "$1" in
      -n|--index)
        if (( $# < 2 )) || ! [[ $2 =~ ^([0-9]|[1-9][0-9]+)$ ]]; then
          echo "\`--index' requires an integer argument: \`$2'" \
            | batslib_decorate 'ERROR: assert_line' \
            | fail
          return $?
        fi
        is_match_line=1
        local -ri idx="$2"
        shift 2
        ;;
      -p|--partial) is_mode_partial=1; shift ;;
      -e|--regexp) is_mode_regexp=1; shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  if (( is_mode_partial )) && (( is_mode_regexp )); then
    echo "\`--partial' and \`--regexp' are mutually exclusive" \
      | batslib_decorate 'ERROR: assert_line' \
      | fail
    return $?
  fi

  # Arguments.
  local -r expected="$1"

  if (( is_mode_regexp == 1 )) && [[ '' =~ $expected ]] || (( $? == 2 )); then
    echo "Invalid extended regular expression: \`$expected'" \
      | batslib_decorate 'ERROR: assert_line' \
      | fail
    return $?
  fi

  # Matching.
  if (( is_match_line )); then
    # Specific line.
    if (( is_mode_regexp )); then
      if ! [[ ${lines[$idx]} =~ $expected ]]; then
        batslib_print_kv_single 6 \
            'index' "$idx" \
            'regexp' "$expected" \
            'line'  "${lines[$idx]}" \
          | batslib_decorate 'regular expression does not match line' \
          | fail
      fi
    elif (( is_mode_partial )); then
      if [[ ${lines[$idx]} != *"$expected"* ]]; then
        batslib_print_kv_single 9 \
            'index'     "$idx" \
            'substring' "$expected" \
            'line'      "${lines[$idx]}" \
          | batslib_decorate 'line does not contain substring' \
          | fail
      fi
    else
      if [[ ${lines[$idx]} != "$expected" ]]; then
        batslib_print_kv_single 8 \
            'index'    "$idx" \
            'expected' "$expected" \
            'actual'   "${lines[$idx]}" \
          | batslib_decorate 'line differs' \
          | fail
      fi
    fi
  else
    # Contained in output.
    if (( is_mode_regexp )); then
      local -i idx
      for (( idx = 0; idx < ${#lines[@]}; ++idx )); do
        [[ ${lines[$idx]} =~ $expected ]] && return 0
      done
      { local -ar single=(
          'regexp'  "$expected"
        )
        local -ar may_be_multi=(
          'output' "$output"
        )
        local -ir width="$( batslib_get_max_single_line_key_width \
                              "${single[@]}" "${may_be_multi[@]}" )"
        batslib_print_kv_single "$width" "${single[@]}"
        batslib_print_kv_single_or_multi "$width" "${may_be_multi[@]}"
      } | batslib_decorate 'no output line matches regular expression' \
        | fail
    elif (( is_mode_partial )); then
      local -i idx
      for (( idx = 0; idx < ${#lines[@]}; ++idx )); do
        [[ ${lines[$idx]} == *"$expected"* ]] && return 0
      done
      { local -ar single=(
          'substring' "$expected"
        )
        local -ar may_be_multi=(
          'output'    "$output"
        )
        local -ir width="$( batslib_get_max_single_line_key_width \
                              "${single[@]}" "${may_be_multi[@]}" )"
        batslib_print_kv_single "$width" "${single[@]}"
        batslib_print_kv_single_or_multi "$width" "${may_be_multi[@]}"
      } | batslib_decorate 'no output line contains substring' \
        | fail
    else
      local -i idx
      for (( idx = 0; idx < ${#lines[@]}; ++idx )); do
        [[ ${lines[$idx]} == "$expected" ]] && return 0
      done
      { local -ar single=(
          'line'   "$expected"
        )
        local -ar may_be_multi=(
          'output' "$output"
        )
        local -ir width="$( batslib_get_max_single_line_key_width \
                            "${single[@]}" "${may_be_multi[@]}" )"
        batslib_print_kv_single "$width" "${single[@]}"
        batslib_print_kv_single_or_multi "$width" "${may_be_multi[@]}"
      } | batslib_decorate 'output does not contain line' \
        | fail
    fi
  fi
}
