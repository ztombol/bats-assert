assert_regex() {
	local -r value="${1}"
	local -r pattern="${2}"

	if [[ '' =~ ${pattern} ]] || (( ${?} == 2 )); then
		echo "Invalid extended regular expression: \`${pattern}'" \
		| batslib_decorate 'ERROR: assert_regex' \
		| fail
	elif ! [[ "${value}" =~ ${pattern} ]]; then
		batslib_print_kv_single_or_multi 8 \
			'value' "${value}" \
			'pattern'  "${pattern}" \
		| batslib_decorate 'value does not match regular expression' \
		| fail
	fi
}
