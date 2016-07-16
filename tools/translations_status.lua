package.path = package.path .. ";../vlsub.lua"
local vlsub = require("vlsub")

-- table methods

function exclude_table_elements(source, elements_to_exclude)
  local destination = {}
  for index, element in pairs(source) do
    if elements_to_exclude[element] == nil then
      destination[#destination + 1] = element
    end
  end
  return destination
end

-- file manipulation

function get_file_translations(file)
  translations = {}
  for line in io.lines(file) do
    key, translation = string.match(line, "<(.*)>(.*)</.*>")
    if key ~= nil then
      translations[key] = translation
    end
  end
  return translations
end

function file_exists(file)
  local file_descriptor = io.open(file, "rb")
  if file_descriptor then file_descriptor:close() end
  return file_descriptor ~= nil
end

function get_missing_langs_files(langs)
  local missing_langs = {}
  for index, lang in pairs(langs) do
    if not file_exists("../locale/"..lang..".xml") then
      missing_langs[lang] = lang
    end
  end
  return missing_langs
end

-- filtering

function filter_missing_translation(translation, base_translation)
  return translation == nil
end

function filter_translation_equality(translation, base_translation)
  return translation == base_translation
end

function filter_translation_difference(translation, base_translation)
  return translation ~= base_translation
end

function find_filtered_translations_warnings(translations, base_translations, filter)
  local translations_warnings = {}
  for key, translation in pairs(base_translations) do
    if filter(translations[key], base_translations[key]) then
      table.insert(translations_warnings, key)
    end
  end
  return translations_warnings
end

-- core

function get_lang_translations_statistics(lang, translations, base_translations)
  local missing_translations = {}
  local translations_warnings = {}
  missing_translations = find_filtered_translations_warnings(translations, base_translations, filter_missing_translation)
  if lang ~= 'eng' then
    translations_warnings = find_filtered_translations_warnings(translations, base_translations, filter_translation_equality)
  else
    translations_warnings = find_filtered_translations_warnings(translations, base_translations, filter_translation_difference)
  end
  return missing_translations, translations_warnings
end

function get_translations_statistics(statistics, base_translations, langs)
  statistics["missing_langs"] = get_missing_langs_files(langs)
  local existing_langs = exclude_table_elements(langs, statistics["missing_langs"])
  for index, lang in pairs(existing_langs) do
    local translations = get_file_translations("../locale/"..lang..".xml")
    statistics["missing_words"][lang], statistics["translation_warnings"][lang] =
      get_lang_translations_statistics(lang, translations, base_translations)
  end
  return statistics
end

-- display

function display_statistic(all_langs_statistics)
  for lang, lang_statistics in pairs(all_langs_statistics) do
    for index, statistic in pairs(lang_statistics) do
      print(lang, statistic)
    end
  end
end

function display_translations_statistics(statistics)
  print("Translation statistics")
  print("-- missing lang files")
  for index, lang in pairs(statistics["missing_langs"]) do
    print(lang)
  end
  print("-- missing translation keys")
  display_statistic(statistics["missing_words"])
  print("-- translations equal to the english version")
  print("-- or xml english translation different from program english translation")
  display_statistic(statistics["translation_warnings"])
end

-- main

local statistics = {}
statistics["missing_langs"] = {}
statistics["missing_words"] = {}
statistics["translation_warnings"] = {}
statistics = get_translations_statistics(statistics, vlsub.options.translation, vlsub.lang_os_to_iso)
display_translations_statistics(statistics)