# Fail and display details if the unexpected line is found in the output
# (default) or in a specific line of it.
#
# By default, the entire output is searched for the unexpected line. The
# unexpected line is matched against every element of `${lines[@]}'. If
# a match is found, the assertion fails. Details include the unexpected
# line, the index of the first match and `${lines[@]}' with the matching
# line highlighted if `${lines[@]}' is longer than one line.
#
# When `--index <idx>' is specified, only the <idx>-th line is matched.
# If the unexpected line matches `${lines[<idx>]}', the assertion fails.
# Details include <idx> and the unexpected line.
#
# By default, literal matching is performed. A literal match fails if
# the unexpected string does not equal the matched string.
#
# Option `--partial' enables partial matching. A partial match fails if
# the unexpected substring is found in the target string. When used with
# `--index <idx>', the unexpected substring is also displayed on
# failure.
#
# Option `--regexp' enables regular expression matching. A regular
# expression match fails if the extended regular expression matches the
# target string. When used with `--index <idx>', the regular expression
# is also displayed on failure. An invalid regular expression causes an
# error to be displayed.
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
#   $1 - unexpected line
# Returns:
#   0 - match not found
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
#            error message, on error
# FIXME(ztombol): Display `${lines[@]}' instead of `$output'!
refute_line() {
  local -i is_match_line=0
  local -i is_mode_partial=0
  local -i is_mode_regexp=0

  # Handle options.
  while (( $# > 0 )); do
    case "$1" in
      -n|--index)
        if (( $# < 2 )) || ! [[ $2 =~ ^([0-9]|[1-9][0-9]+)$ ]]; then
          echo "\`--index' requires an integer argument: \`$2'" \
            | batslib_decorate 'ERROR: refute_line' \
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
      | batslib_decorate 'ERROR: refute_line' \
      | fail
    return $?
  fi

  # Arguments.
  local -r unexpected="$1"

  if (( is_mode_regexp == 1 )) && [[ '' =~ $unexpected ]] || (( $? == 2 )); then
    echo "Invalid extended regular expression: \`$unexpected'" \
      | batslib_decorate 'ERROR: refute_line' \
      | fail
    return $?
  fi

  # Matching.
  if (( is_match_line )); then
    # Specific line.
    if (( is_mode_regexp )); then
      if [[ ${lines[$idx]} =~ $unexpected ]] || (( $? == 0 )); then
        batslib_print_kv_single 6 \
            'index' "$idx" \
            'regexp' "$unexpected" \
            'line'  "${lines[$idx]}" \
          | batslib_decorate 'regular expression should not match line' \
          | fail
      fi
    elif (( is_mode_partial )); then
      if [[ ${lines[$idx]} == *"$unexpected"* ]]; then
        batslib_print_kv_single 9 \
            'index'     "$idx" \
            'substring' "$unexpected" \
            'line'      "${lines[$idx]}" \
          | batslib_decorate 'line should not contain substring' \
          | fail
      fi
    else
      if [[ ${lines[$idx]} == "$unexpected" ]]; then
        batslib_print_kv_single 5 \
            'index' "$idx" \
            'line'  "${lines[$idx]}" \
          | batslib_decorate 'line should differ' \
          | fail
      fi
    fi
  else
    # Line contained in output.
    if (( is_mode_regexp )); then
      local -i idx
      for (( idx = 0; idx < ${#lines[@]}; ++idx )); do
        if [[ ${lines[$idx]} =~ $unexpected ]]; then
          { local -ar single=(
              'regexp'  "$unexpected"
              'index'  "$idx"
            )
            local -a may_be_multi=(
              'output' "$output"
            )
            local -ir width="$( batslib_get_max_single_line_key_width \
                                "${single[@]}" "${may_be_multi[@]}" )"
            batslib_print_kv_single "$width" "${single[@]}"
            if batslib_is_single_line "${may_be_multi[1]}"; then
              batslib_print_kv_single "$width" "${may_be_multi[@]}"
            else
              may_be_multi[1]="$( printf '%s' "${may_be_multi[1]}" \
                                    | batslib_prefix \
                                    | batslib_mark '>' "$idx" )"
              batslib_print_kv_multi "${may_be_multi[@]}"
            fi
          } | batslib_decorate 'no line should match the regular expression' \
            | fail
          return $?
        fi
      done
    elif (( is_mode_partial )); then
      local -i idx
      for (( idx = 0; idx < ${#lines[@]}; ++idx )); do
        if [[ ${lines[$idx]} == *"$unexpected"* ]]; then
          { local -ar single=(
              'substring' "$unexpected"
              'index'     "$idx"
            )
            local -a may_be_multi=(
              'output'    "$output"
            )
            local -ir width="$( batslib_get_max_single_line_key_width \
                                "${single[@]}" "${may_be_multi[@]}" )"
            batslib_print_kv_single "$width" "${single[@]}"
            if batslib_is_single_line "${may_be_multi[1]}"; then
              batslib_print_kv_single "$width" "${may_be_multi[@]}"
            else
              may_be_multi[1]="$( printf '%s' "${may_be_multi[1]}" \
                                    | batslib_prefix \
                                    | batslib_mark '>' "$idx" )"
              batslib_print_kv_multi "${may_be_multi[@]}"
            fi
          } | batslib_decorate 'no line should contain substring' \
            | fail
          return $?
        fi
      done
    else
      local -i idx
      for (( idx = 0; idx < ${#lines[@]}; ++idx )); do
        if [[ ${lines[$idx]} == "$unexpected" ]]; then
          { local -ar single=(
              'line'   "$unexpected"
              'index'  "$idx"
            )
            local -a may_be_multi=(
              'output' "$output"
            )
            local -ir width="$( batslib_get_max_single_line_key_width \
                                "${single[@]}" "${may_be_multi[@]}" )"
            batslib_print_kv_single "$width" "${single[@]}"
            if batslib_is_single_line "${may_be_multi[1]}"; then
              batslib_print_kv_single "$width" "${may_be_multi[@]}"
            else
              may_be_multi[1]="$( printf '%s' "${may_be_multi[1]}" \
                                    | batslib_prefix \
                                    | batslib_mark '>' "$idx" )"
              batslib_print_kv_multi "${may_be_multi[@]}"
            fi
          } | batslib_decorate 'line should not be in output' \
            | fail
          return $?
        fi
      done
    fi
  fi
}
