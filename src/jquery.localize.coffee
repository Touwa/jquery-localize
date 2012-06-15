# Copyright (c) Jim Garvin (http://github.com/coderifous), 2008.
# Dual licensed under the GPL (http://dev.jquery.com/browser/trunk/jquery/GPL-LICENSE.txt) and MIT (http://dev.jquery.com/browser/trunk/jquery/MIT-LICENSE.txt) licenses.
# Written by Jim Garvin (@coderifous) for use on LMGTFY.com.
# http://github.com/coderifous/jquery-localize
# Based off of Keith Wood's Localisation jQuery plugin.
# http://keith-wood.name/localisation.html

$ = jQuery

# Ensures language code is in the format aa-AA.
normaliseLang = (lang) ->
  lang = lang.replace(/_/, '-').toLowerCase()
  if lang.length > 3
    lang = lang.substring(0, 3) + lang.substring(3).toUpperCase()
  lang

# Mozilla uses .language, IE uses .userLanguage
$.defaultLanguage = normaliseLang(navigator.language || navigator.userLanguage)

$.localize = (pkg, options = {}) ->
  wrappedSet = this
  intermediateLangData = {}
  fileExtension = options.fileExtension || "json"

  loadLanguage = (pkg, lang, level = 1) ->
    switch level
      when 1
        intermediateLangData = {}
        if options.loadBase
          file = pkg + ".#{fileExtension}"
          jsonCall(file, pkg, lang, level)
        else
          loadLanguage(pkg, lang, 2)
      when 2
        if lang.length >= 2
          file = "#{pkg}-#{lang.substring(0, 2)}.#{fileExtension}"
          jsonCall(file, pkg, lang, level)
      when 3
        if lang.length >= 5
          file = "#{pkg}-#{lang.substring(0, 5)}.#{fileExtension}"
          jsonCall(file, pkg, lang, level)

  jsonCall = (file, pkg, lang, level) ->
    file = "#{options.pathPrefix}/#{file}" if options.pathPrefix?
    successFunc = (d) ->
      $.extend(intermediateLangData, d)
      notifyDelegateLanguageLoaded(intermediateLangData)
      loadLanguage(pkg, lang, level + 1)
    ajaxOptions =
      url: file
      dataType: "json"
      async: false
      timeout: if options.timeout? then options.timeout else 500
      success: successFunc
    # hack to work with serving from local file system.
    # local file:// urls won't work in chrome:
    # http://code.google.com/p/chromium/issues/detail?id=40787
    if window.location.protocol == "file:"
      ajaxOptions.error = (xhr) -> successFunc($.parseJSON(xhr.responseText))
    $.ajax(ajaxOptions)

  defaultCallback = (data) ->
    $.localize.data[pkg] = data
    wrappedSet.each ->
      elem = $(this)
      key = elem.data("localize")
      key ||= elem.attr("rel").match(/localize\[(.*?)\]/)[1]
      value = valueForKey(key, data)
      if elem.is('input')
        if elem.is("[placeholder]")
          elem.attr("placeholder", value)
        else
          elem.val(value)
      else if elem.is('optgroup')
        elem.attr("label", value)
      else if elem.is('img')
        applyValueToAttribute(key, "alt", data, elem)
        applyValueToAttribute(key, "src", data, elem)
      else unless $.isPlainObject(value)
        elem.html(value)

      if $.isPlainObject(value)
        applyValueToAttribute(key, "title", data, elem)
        value = valueForKey("#{key}.text", data)
        elem.text(value) if value?

  notifyDelegateLanguageLoaded = (data) ->
    if options.callback?
      options.callback(data, defaultCallback)
    else
      defaultCallback(data)

  valueForKey = (key, data) ->
    keys  = key.split(/\./)
    value = data
    for key in keys
      value = if value? then value[key] else null
    value

  applyValueToAttribute = (key, attribute, data, elem) ->
    value = valueForKey("#{key}.#{attribute}", data)
    elem.attr(attribute, value) if value?

  regexify = (string_or_regex_or_array) ->
    if typeof(string_or_regex_or_array) == "string"
      "^" + string_or_regex_or_array + "$"
    else if string_or_regex_or_array.length?
      (regexify(thing) for thing in string_or_regex_or_array).join("|")
    else
      string_or_regex_or_array

  lang = normaliseLang(if options.language then options.language else $.defaultLanguage)
  loadLanguage(pkg, lang, 1) unless (options.skipLanguage && lang.match(regexify(options.skipLanguage)))

  wrappedSet

$.fn.localize = $.localize
$.localize.data = {}
