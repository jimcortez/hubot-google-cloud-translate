# Description:
#   Allows Hubot to know many languages.
#
# Commands:
#   hubot translate me <phrase> - Searches for a translation for the <phrase> and then prints that bad boy out.
#   hubot translate me from <source> into <target> <phrase> - Translates <phrase> from <source> into <target>. Both <source> and <target> are optional

Translate = require('@google-cloud/translate').v2.Translate
ISO6391 = require('iso-639-1')
escapeStringRegexp = require('escape-string-regexp');

# Some languages just need a bit of a shorter name
languageNiceNames =
  "Chinese": "Simplified Chinese",
  "Creole": "Haitian Creole",
  "Kurdish": "Kurdish (Kurmanji)",
  "Kurmanji": "Kurdish (Kurmanji)",
  "Burmese": "Myanmar (Burmese)",
  "Myanmar": "Myanmar (Burmese)",

getCode = (language,supportedLanguages) ->
  #first resolve using a nice library
  code = ISO6391.getCode(language)
  if supportedLanguages[code]
    return code

  #see if we have a nice name mapping
  niceName = language
  for short, lang of languageNiceNames
    if short.toLowerCase() == language.toLowerCase()
      niceName = short

  #match directly against the supported languages
  for code, lang of supportedLanguages
      return code if lang.toLowerCase() is niceName.toLowerCase()

getNamesFromCode = (code) ->
  return [
    code,
    ISO6391.getCode(code),
    ISO6391.getNativeName(code)
  ]

getSupportedLanguages = (translate) ->
  return translate.getLanguages().then (googleSupportedLanguagesResponse) ->
    googleSupportedLanguages = googleSupportedLanguagesResponse[0]
    supportedLanguages = {}
    for supportedLanguage, i in googleSupportedLanguages
      supportedLanguages[supportedLanguage.code] = supportedLanguage.name
    return supportedLanguages

getLanguageRegex = (supportedLanguages) ->
  language_names = (language for _, language of supportedLanguages)
  language_extended_names = Array::flat.apply((getNamesFromCode(code) for code, _ of supportedLanguages))
  nice_names = (language for language, _ of languageNiceNames)
  language_choices = Array::flat.apply([language_names, language_extended_names, nice_names]).map(escapeStringRegexp)

  unique_language_choices = language_choices.filter (c, index) ->
    return c and language_choices.indexOf(c) == index

  #reverse sort, want longer names first
  return unique_language_choices \
    .sort((a, b) -> return b.toLowerCase().localeCompare(a.toLowerCase())) \
    .join("|")

getTranslation = (term, target, translate) ->
  return translate.translate(term, target).then (translationsResponse) ->
    if Array.isArray(translationsResponse) and translationsResponse.length > 1
      translationObj = translationsResponse[1]?.data?.translations
      if translationObj.length > 0
        return translationObj[0]
      else
        throw Error('No translations found in google cloud response')
    else
      throw Error('Malformed google cloud response')


module.exports = (robot) ->
  translate = new Translate();

  getSupportedLanguages(translate).then (supportedLanguages) ->
    language_choices_regex = getLanguageRegex(supportedLanguages)

    pattern = new RegExp('translate(?: me)?' +
                         "(?: from (#{language_choices_regex}))?" +
                         "(?: (?:in)?to (#{language_choices_regex}))?" +
                         '(.*)', 'i')

    robot.respond pattern, (msg) ->
        term   = "\"#{msg.match[3]?.trim()}\""
        origin = if msg.match[1] isnt undefined then getCode(msg.match[1], supportedLanguages) else 'auto'
        target = if msg.match[2] isnt undefined then getCode(msg.match[2], supportedLanguages) else 'en'

        getTranslation(term, target, translate).then (translationsResponse) ->
          translation = translationsResponse.translatedText
          detectedSourceLanguage = translationsResponse.detectedSourceLanguage

          if msg.match[2] is undefined
            msg.send "#{term} is #{supportedLanguages[detectedSourceLanguage]} for #{translation}"
          else
            originPretty = if origin == "auto" then "English" else supportedLanguages[origin]
            msg.send "#{originPretty} #{term} translates as #{translation} in #{supportedLanguages[target]}"

        .catch (err) ->
          robot.emit 'error', err
          msg.send('Error fetching translation');
  .catch (err) ->
    robot.logger.error("Something went wrong configuring translate api")
    robot.emit 'error', err
