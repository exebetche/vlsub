require "lunit"
package.path = package.path .. ";../vlsub.lua"
local vlsub = require("vlsub")

module( "vlc_interface_data", lunit.testcase )

function test_movie_length_text_shouldReturnNone_WhenNoMovie()
  -- Given
  function item_mock(string)
    return nil
  end
  vlc_mock = {input={item=item_mock}}
  lang_mock = {int_movie_duration="movie duration"}
  -- When
  local result = vlsub.movie_duration_text(vlc_mock, lang_mock)
  -- Then
  assert_equal(result, "movie duration : ?")
end

function test_movie_length_text_shouldReturnNone_WhenMovieHasNone()
  -- Given
  function item_mock(string)
    return {duration=function() return -1 end}
  end
  vlc_mock = {input={item=item_mock}}
  lang_mock = {int_movie_duration="movie duration"}
  -- When
  local result = vlsub.movie_duration_text(vlc_mock, lang_mock)
  -- Then
  assert_equal(result, "movie duration : ?")
end

function test_movie_length_text_shouldReturnLength_WhenMovieHasOne()
  -- Given
  function item_mock(string)
    return {duration=function() return 70 end}
  end
  vlc_mock = {input={item=item_mock}}
  lang_mock = {int_movie_duration="movie duration"}
  -- When
  local result = vlsub.movie_duration_text(vlc_mock, lang_mock)
  -- Then
  assert_equal(result, "movie duration : 00:01:10")
end
