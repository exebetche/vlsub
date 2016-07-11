require "lunit"
package.path = package.path .. ";../vlsub.lua"
local vlsub = require("vlsub")

module( "vlc_core", lunit.testcase )

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
