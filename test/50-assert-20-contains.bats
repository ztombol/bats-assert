#!/usr/bin/env bats

load test_helper

@test 'assert_contains() <item> <items>: returns 0 if <item> is in <items>' {
  local items=(one two three)
  run assert_contains two ${items[@]}

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test 'assert_contains() <item> <items>: returns 1 and displays details if <item> is not in <items>' {
  local items=(one two three)
  run assert_contains four ${items[@]}

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[0]}" == '-- item was not found in the array --' ]
  [ "${lines[1]}" == 'expected : four' ]
  [ "${lines[2]}" == 'actual   : one two three' ]
  [ "${lines[3]}" == '--' ]
}