require "lunit"
package.path = package.path .. ";../vlsub.lua"
local vlsub = require("vlsub")

module( "vlsub_core", lunit.testcase, package.seeall)

function test_last_subtitle_time_text_shouldReturnQuestionMark_WhenNoDuration()
  -- Given
  lang_mock = {int_last_sub="last sub at"}
  subtitle_mock = {SubLastTS=nil}
  -- When
  local result = vlsub.last_subtitle_time_text(subtitle_mock, lang_mock)
  -- Then
  assert_equal("[last sub at ?]", result)
end

function test_last_subtitle_time_text_shouldReturnQuestionMark_WhenDurationFormatIsWrong()
  -- Given
  lang_mock = {int_last_sub="last sub at"}
  subtitle_mock = {SubLastTS="123456"}
  -- When
  local result = vlsub.last_subtitle_time_text(subtitle_mock, lang_mock)
  -- Then
  assert_equal("[last sub at ?]", result)
end

function test_last_subtitle_time_text_shouldReturnDuration_WhenDurationFormatIsRight()
  -- Given
  lang_mock = {int_last_sub="last sub at"}
  subtitle_mock = {SubLastTS="12:34:56"}
  -- When
  local result = vlsub.last_subtitle_time_text(subtitle_mock, lang_mock)
  -- Then
  assert_equal("[last sub at 12:34:56]", result)
end

function test_date_string_to_time_shouldReturnTime_FromStringFormatedWithHoursMinutesSeconds()
  -- When
  local result = vlsub.date_string_to_time("01:02:03")

  -- Then
  assert_equal(3723, result)
end

function test_date_string_to_time_shouldReturnZero_WhenGivenMalformatedString()
  -- When
  local result = vlsub.date_string_to_time("01.23azerty")

  -- Then
  assert_equal(0, result)
end

function test_order_subs_shouldOrderUnorderedSubs_ByDistanceBetweenLastSpokenLineAndMovieDuration()
  -- Given
  local movie_duration = 60
  local unordered_table = {}
  local incorrect = {SubLastTS="xxxxx"}
  local greater = {SubLastTS="00:01:10"}
  local equals = {SubLastTS="00:01:00"}
  local lesser = {SubLastTS="00:00:10"}
  table.insert(unordered_table, greater)
  table.insert(unordered_table, incorrect)
  table.insert(unordered_table, equals)
  table.insert(unordered_table, lesser)

  -- When
  local result = vlsub.order_by_ascending_distance_between_last_sub_time_and_movie_duration(unordered_table, movie_duration)

  -- Then
  assert_equal(table_tostring({equals, greater, lesser, incorrect}), table_tostring(result))
end

-- test-utils
function table_val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table_tostring( v ) or
      tostring( v )
  end
end

function table_key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table_val_to_str( k ) .. "]"
  end
end

function table_tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table_val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table_key_to_str( k ) .. "=" .. table_val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end