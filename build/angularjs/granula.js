;(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function() {
  var defaultOptions, granulaCtor, keys, processDomText,
    __slice = [].slice;

  granulaCtor = require('../granula/granula');

  keys = require('../granula/keys');

  angular.module('granula', []);

  defaultOptions = require('../runner/defaultOptions');

  angular.module('granula').provider('grService', function() {
    var angularInterpolator, argumentNamesByKey, asyncLoaders, granula, mapArgumentByKey, options, peCache, pluralInterpolator, removeOwnDirectives;
    granula = granulaCtor();
    argumentNamesByKey = {};
    options = defaultOptions;
    removeOwnDirectives = function(argName) {
      var foundAt;
      foundAt = argName.search(/\|\s*grPluralize/i);
      if (foundAt !== -1) {
        return argName.substring(0, foundAt);
      } else {
        return argName;
      }
    };
    mapArgumentByKey = function(key) {
      argumentNamesByKey[key] || (argumentNamesByKey[key] = [null]);
      return function(name) {
        if (name.match(/[0-9]+/)) {
          return argumentNamesByKey[key][name];
        } else {
          if (argumentNamesByKey[key].indexOf(name) === -1) {
            argumentNamesByKey[key].push(name);
          }
          return name;
        }
      };
    };
    angularInterpolator = function(mapArgument) {
      if (mapArgument == null) {
        mapArgument = function(name) {
          return name;
        };
      }
      return {
        begin: function() {},
        string: function(ctx, text) {
          return text;
        },
        argument: function(ctx, _arg) {
          var argName;
          argName = _arg.argName;
          return "{{" + (mapArgument(argName)) + "}}";
        },
        pluralExpression: function(ctx, _arg, _arg1) {
          var argName, suffixes, word;
          word = _arg.word, suffixes = _arg.suffixes;
          argName = _arg1.argName;
          return "{{" + (removeOwnDirectives(mapArgument(argName))) + " | grPluralize:'" + word + "(" + (suffixes.join(',')) + ")'}}";
        },
        end: function() {}
      };
    };
    pluralInterpolator = function() {
      return {
        string: function() {
          return "";
        },
        argument: function() {
          return "";
        },
        pluralExpression: function(context, _arg) {
          var fn;
          fn = _arg.fn;
          return fn(context.attrs[1]);
        }
      };
    };
    peCache = {};
    asyncLoaders = {};
    return {
      config: function(opts) {
        return angular.extend(options, defaultOptions, opts);
      },
      $get: function($rootScope) {
        var wrap;
        wrap = function(language, dataToWrap) {
          var data;
          data = {};
          data[language] = dataToWrap != null ? dataToWrap : {};
          return data;
        };
        return {
          language: "en",
          originalLanguage: "en",
          toKey: function(attribute, text) {
            return keys.toKey(attribute, text, options);
          },
          isOriginal: function() {
            return this.language === this.originalLanguage;
          },
          _registerOriginal: function() {
            this.register(this.originalLanguage);
            return this._registerOriginal = function() {};
          },
          setOriginalLanguage: function(lang) {
            this.originalLanguage = lang;
            return this._registerOriginal();
          },
          setLanguage: function(lang) {
            var loadAsync, loadSync, _ref,
              _this = this;
            if (lang === this.language && !asyncLoaders[lang]) {
              return;
            }
            if ((_ref = asyncLoaders[lang]) != null ? _ref.loading : void 0) {
              return;
            }
            this._loading = lang;
            loadAsync = function(onLoad) {
              $rootScope.$broadcast('gr-lang-load', lang);
              asyncLoaders[lang].loading = asyncLoaders[lang].length;
              return asyncLoaders[lang].forEach(function(loader) {
                return loader(function(error, data) {
                  if (error) {
                    console.error(error);
                    return $rootScope.$broadcast('gr-lang-load-error', error);
                  } else {
                    _this.register(lang, data);
                    asyncLoaders[lang].loading--;
                    if (asyncLoaders[lang].loading === 0) {
                      delete asyncLoaders[lang];
                      return onLoad();
                    }
                  }
                });
              });
            };
            loadSync = function() {
              if (lang !== _this._loading) {
                return;
              }
              _this.language = lang;
              return $rootScope.$broadcast('gr-lang-changed', lang);
            };
            if (asyncLoaders[lang]) {
              return loadAsync(function() {
                return loadSync();
              });
            } else {
              return loadSync();
            }
          },
          register: function(language, data_or_loader) {
            if (!language) {
              throw new Error("language shall be defined!");
            }
            if (angular.isFunction(data_or_loader)) {
              if (asyncLoaders[language] == null) {
                asyncLoaders[language] = [];
              }
              return asyncLoaders[language].push(data_or_loader);
            } else {
              return granula.load(wrap(language, data_or_loader));
            }
          },
          save: function(key, pattern, language) {
            var data;
            if (language == null) {
              language = this.originalLanguage;
            }
            data = wrap(language);
            data[language][key] = pattern;
            return granula.load(data);
          },
          canTranslate: function(key, language) {
            if (language == null) {
              language = this.language;
            }
            return granula.canTranslate(language, key);
          },
          canTranslateTo: function(language) {
            if (language == null) {
              language = this.language;
            }
            return granula.canTranslateTo(language) || asyncLoaders[language];
          },
          translate: function() {
            var args, options, pattern, realKey;
            pattern = arguments[0], options = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
            if (options == null) {
              options = {};
            }
            if (angular.isObject(pattern)) {
              options = pattern;
              pattern = null;
            }
            if (angular.isObject(options)) {
              angular.extend(options, {
                language: this.language
              });
            } else {
              args.unshift(options);
              options = {
                language: this.language
              };
            }
            if (asyncLoaders[options.language]) {
              return "";
            }
            realKey = this.toKey(options.key, pattern);
            if (this.isOriginal() && pattern) {
              this.save(realKey, pattern, options.language);
            }
            return granula.translate(options.language, realKey, args);
          },
          compile: function(key, language, skipIfEmpty) {
            var e;
            if (language == null) {
              language = this.language;
            }
            if (skipIfEmpty == null) {
              skipIfEmpty = true;
            }
            this._registerOriginal();
            if (argumentNamesByKey[key] === void 0 && language !== this.originalLanguage) {
              this.compile(key, this.originalLanguage, false);
            }
            try {
              return granula.compile(language, {
                key: key
              }).apply(angularInterpolator(mapArgumentByKey(key)));
            } catch (_error) {
              e = _error;
              if (!asyncLoaders[language]) {
                if (!skipIfEmpty) {
                  throw e;
                }
                console.error(e.message, e);
              }
              return "";
            }
          },
          plural: function(expression, value) {
            var compiled, _ref,
              _this = this;
            compiled = (_ref = peCache[expression]) != null ? _ref : (function() {
              return peCache[expression] = granula.compile(_this.language, "" + expression + ":1");
            })();
            return compiled.apply(pluralInterpolator(), value);
          }
        };
      }
    };
  });

  angular.module('granula').filter('grPluralize', function(grService) {
    return function(input, pluralExpression) {
      return grService.plural(pluralExpression, input);
    };
  });

  angular.module('granula').directive('grStatus', function() {
    return function(scope, el) {
      scope.$on('gr-lang-load', function() {
        return el.addClass("gr-lang-load");
      });
      scope.$on('gr-lang-load-error', function() {
        return el.removeClass("gr-lang-load");
      });
      return scope.$on('gr-lang-changed', function() {
        return el.removeClass("gr-lang-load");
      });
    };
  });

  angular.module('granula').directive('grLang', function($rootScope, grService, $interpolate, $http) {
    var compileOther, compileScript;
    compileScript = function(el, attrs) {
      var e, langName;
      langName = attrs.grLang;
      if ((langName != null ? langName : "").length === 0) {
        throw new Error("gr-lang for script element shall have value - name of language");
      }
      if (attrs.src) {
        grService.register(langName, function(cb) {
          var _this = this;
          return $http({
            method: "GET",
            url: attrs.src
          }).success(function(data) {
            return cb(null, data);
          }).error(function() {
            return cb("Cannot load " + attrs.src + " for language " + langName);
          });
        });
      } else {
        try {
          grService.register(langName, JSON.parse(el.text()));
        } catch (_error) {
          e = _error;
          throw new Error("Cannot parse json for language '" + langName + "'", e);
        }
      }
      return void 0;
    };
    compileOther = function(el, attrs) {
      var requireInterpolation;
      if (attrs.grLangOfText) {
        grService.setOriginalLanguage(attrs.grLangOfText);
      }
      requireInterpolation = $interpolate(attrs.grLang, true);
      if (requireInterpolation || !grService.canTranslateTo(attrs.grLang)) {
        grService.setLanguage(grService.originalLanguage);
      } else {
        grService.setLanguage(attrs.grLang);
      }
      return function(scope, el, attrs) {
        return attrs.$observe("grLang", function(newVal) {
          if (newVal.length) {
            return grService.setLanguage(newVal);
          }
        });
      };
    };
    return {
      compile: function(el, attrs) {
        if (el[0].tagName === 'SCRIPT') {
          return compileScript(el, attrs);
        } else {
          return compileOther(el, attrs);
        }
      }
    };
  });

  processDomText = function(grService, $interpolate, interpolateKey, startKey, readTextFn, writeTextFn, el) {
    var compiled, interpolateFn, pattern;
    pattern = readTextFn(el);
    if (startKey) {
      grService.save(startKey, pattern);
      compiled = grService.compile(startKey);
      interpolateFn = $interpolate(compiled, true);
    }
    if (interpolateFn || interpolateKey) {
      writeTextFn(el, '');
    }
    return {
      link: function(scope, el) {
        var key, onKeyChanged, onLanguageChanged, onVariablesChanged, outputFn;
        outputFn = interpolateFn;
        key = startKey;
        onLanguageChanged = function() {
          outputFn = $interpolate(grService.compile(key));
          return writeTextFn(el, outputFn(scope));
        };
        onVariablesChanged = function(text) {
          if (grService.language === grService.originalLanguage) {
            return writeTextFn(el, text);
          }
          if (!outputFn) {
            throw new Error("outputFn is undefined but it shall not be");
          }
          return writeTextFn(el, outputFn(scope));
        };
        onKeyChanged = function(newKey) {
          if (key === newKey) {
            return;
          }
          key = newKey;
          return onLanguageChanged();
        };
        scope.$on("gr-lang-changed", function() {
          return onLanguageChanged();
        });
        if (interpolateFn) {
          scope.$watch(interpolateFn, function(text) {
            return onVariablesChanged(text);
          });
        }
        if (interpolateKey) {
          scope.$watch(interpolateKey, function(newVal) {
            return onKeyChanged(newVal);
          });
        }
        if (startKey) {
          onLanguageChanged();
        }
        return {
          onKeyChanged: onKeyChanged
        };
      }
    };
  };

  angular.module('granula').directive('grAttrs', function(grService, $interpolate) {
    var read, write;
    read = function(attrName) {
      return function(el) {
        return el.attr(attrName);
      };
    };
    write = function(attrName) {
      return function(el, val) {
        return el.attr(attrName, val);
      };
    };
    return {
      compile: function(el, attrs) {
        var attrNames, linkFunctions;
        attrNames = attrs.grAttrs.split(",");
        linkFunctions = attrNames.map(function(attrName) {
          var attrWithKeyValue, interpolateKey, keyExpr, startKey;
          attrWithKeyValue = "grKey" + (attrName[0].toUpperCase() + attrName.substring(1));
          keyExpr = grService.toKey(attrs[attrWithKeyValue], el.attr(attrName));
          if (attrs[attrWithKeyValue]) {
            interpolateKey = $interpolate(keyExpr, true);
          }
          startKey = interpolateKey ? null : keyExpr;
          return {
            link: processDomText(grService, $interpolate, interpolateKey, startKey, read(attrName), write(attrName), el).link,
            attrName: attrName
          };
        });
        return function(scope, el, attrs) {
          var keyListeners;
          return keyListeners = linkFunctions.map(function(l) {
            return l.link(scope, el).onKeyChanged;
          });
        };
      }
    };
  });

  angular.module('granula').directive('grKey', function(grService, $interpolate) {
    var read, write;
    read = function(el) {
      return el.html();
    };
    write = function(el, val) {
      return el.html(val);
    };
    return {
      compile: function(el, attrs) {
        var interpolateKey, keyExpr, link, startKey;
        keyExpr = grService.toKey(attrs.grKey, el.text());
        if (attrs.grKey) {
          interpolateKey = $interpolate(keyExpr, true);
        }
        startKey = interpolateKey ? null : keyExpr;
        link = processDomText(grService, $interpolate, interpolateKey, startKey, read, write, el).link;
        return function(scope, el, attrs) {
          return link(scope, el);
        };
      }
    };
  });

}).call(this);

},{"../granula/granula":4,"../granula/keys":6,"../runner/defaultOptions":8}],2:[function(require,module,exports){
(function() {
  var context,
    __slice = [].slice;

  context = function(attributes, interpolator) {
    var attr, ctx, idx, key, noop, value, _i, _len, _ref;
    ctx = {
      attrs: {}
    };
    if (attributes.length === 1 && typeof attributes[0] === 'object') {
      _ref = attributes[0];
      for (key in _ref) {
        value = _ref[key];
        ctx.attrs[key] = value;
      }
    } else {
      for (idx = _i = 0, _len = attributes.length; _i < _len; idx = ++_i) {
        attr = attributes[idx];
        ctx.attrs[idx + 1] = attr;
      }
    }
    noop = function() {};
    ctx.interpolate = function() {
      var data, method, _ref1;
      method = arguments[0], data = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return ((_ref1 = interpolator[method]) != null ? _ref1 : noop).apply(null, [ctx].concat(__slice.call(data)));
    };
    ctx.begin = function() {
      return typeof interpolator.begin === "function" ? interpolator.begin(ctx) : void 0;
    };
    ctx.end = function(result) {
      return typeof interpolator.end === "function" ? interpolator.end(ctx, result) : void 0;
    };
    ctx.apply = function(fn) {
      var res, _ref1;
      ctx.begin();
      res = fn(ctx);
      return (_ref1 = ctx.end(res)) != null ? _ref1 : res;
    };
    return ctx;
  };

  module.exports = {
    context: context
  };

}).call(this);

},{}],3:[function(require,module,exports){
(function() {
  var argument, argumentParser, justText, noParser, pluralPartsToString, pluralizerParser;

  justText = function(text) {
    return {
      apply: function(context) {
        var _ref;
        return (_ref = context.interpolate("string", text)) != null ? _ref : text;
      }
    };
  };

  argument = function(argName) {
    return {
      argName: argName,
      apply: function(context) {
        return context.interpolate('argument', {
          argName: argName
        });
      }
    };
  };

  argumentParser = function(startSymbol, endSymbol) {
    if (startSymbol == null) {
      startSymbol = "{{";
    }
    if (endSymbol == null) {
      endSymbol = "}}";
    }
    return {
      nextPosition: function(str, from) {
        return str.indexOf(startSymbol, from);
      },
      process: function(str, from, context) {
        var argName, endPos;
        endPos = str.indexOf(endSymbol, from);
        if (endPos === -1) {
          throw new Error("Syntax error: uncompleted argument definition started at char " + from + ": " + str + " ");
        }
        argName = str.substring(from + startSymbol.length, endPos);
        return {
          part: argument(argName),
          currentPos: endPos + endSymbol.length
        };
      }
    };
  };

  noParser = function() {
    return {
      nextPosition: function() {
        return -1;
      }
    };
  };

  pluralPartsToString = function(word, suffixes) {
    return "" + word + "(" + (suffixes.join(',')) + ")";
  };

  pluralizerParser = function(preparePluralizationFn) {
    var endSymbol, escape, exactVarSpec, nearestRight, plural, separator, startSymbol, varEnd, wordSeparator;
    if (!preparePluralizationFn) {
      return noParser();
    }
    startSymbol = "(";
    endSymbol = ")";
    escape = "\\";
    separator = ",";
    wordSeparator = /[\s,.!:;'\"-+=*%$#@{}()]/;
    varEnd = /[\s,!:'\"+=*%$#@{}()-]/;
    exactVarSpec = ":";
    nearestRight = [">", "&gt;"];
    plural = function(word, suffixes, argName) {
      var fn;
      fn = preparePluralizationFn(word, suffixes);
      return {
        argument: typeof argName === "string" ? argument(argName) : null,
        apply: function(context) {
          return context.interpolate("pluralExpression", {
            word: word,
            suffixes: suffixes,
            fn: fn
          }, this.argument);
        },
        link: function(context, myIdx) {
          var dir, i, searchIn, _i, _j, _k, _len, _ref, _results, _results1;
          if (this.argument !== null) {
            return;
          }
          if (argName.prev === true) {
            searchIn = (function() {
              _results = [];
              for (var _i = myIdx; myIdx <= 0 ? _i <= 0 : _i >= 0; myIdx <= 0 ? _i++ : _i--){ _results.push(_i); }
              return _results;
            }).apply(this);
            dir = "left";
          } else if (argName.next === true) {
            searchIn = (function() {
              _results1 = [];
              for (var _j = myIdx, _ref = context.parts.length - 1; myIdx <= _ref ? _j <= _ref : _j >= _ref; myIdx <= _ref ? _j++ : _j--){ _results1.push(_j); }
              return _results1;
            }).apply(this);
            dir = "right";
          } else {
            throw new Error("invalid link " + argName + " - expected {prev:true} or {next:true}");
          }
          for (_k = 0, _len = searchIn.length; _k < _len; _k++) {
            i = searchIn[_k];
            if (context.parts[i].argName) {
              this.argument = context.parts[i];
              break;
            }
          }
          if (this.argument === null) {
            throw new Error("There is no argument nearest to the " + dir + " for plural expression '" + (pluralPartsToString(word, suffixes)) + ")'");
          }
        }
      };
    };
    return {
      nextPosition: function(str, from) {
        var pos, _ref;
        pos = str.indexOf(startSymbol, from);
        while (pos >= from && !((_ref = str[pos - 1]) != null ? _ref : ' ').match(wordSeparator)) {
          pos--;
        }
        return pos;
      },
      process: function(str, from, context) {
        var argLink, cPos, end, exactVar, parts, pluralExpression, startVar;
        end = str.indexOf(endSymbol, from);
        pluralExpression = str.substring(from, end);
        parts = pluralExpression.split(startSymbol);
        if (parts[0].length > 0 && parts[0].slice(-1) === escape) {
          return {
            part: justText("" + (parts[0].slice(0, -1)) + startSymbol + parts[1] + endSymbol),
            currentPos: end + endSymbol.length
          };
        } else {
          argLink = {
            prev: true
          };
          cPos = end + endSymbol.length;
          if (str[end + endSymbol.length] === exactVarSpec) {
            startVar = end + endSymbol.length + 1;
            end = startVar;
            while (end < str.length && !str[end].match(varEnd)) {
              end++;
            }
            exactVar = str.substring(startVar, end);
            if (nearestRight.indexOf(exactVar) > -1) {
              argLink = {
                next: true
              };
              cPos = end;
            } else if (exactVar.length > 0) {
              argLink = exactVar;
              cPos = end;
            }
          }
          return {
            part: plural(parts[0], parts[1].split(separator), argLink),
            currentPos: cPos
          };
        }
      }
    };
  };

  module.exports = {
    argumentParser: argumentParser,
    pluralizerParser: pluralizerParser,
    justText: justText
  };

}).call(this);

},{}],4:[function(require,module,exports){
(function() {
  var argumentParser, context, justText, notEmpty, pluralization, pluralizerParser, precompile, stringInterpolator, _ref,
    __slice = [].slice;

  _ref = require('./compile/parsers'), argumentParser = _ref.argumentParser, pluralizerParser = _ref.pluralizerParser, justText = _ref.justText;

  stringInterpolator = require('./interpolators').stringInterpolator;

  context = require('./compile/context').context;

  pluralization = require('./pluralization')();

  module.exports = function(options) {
    var lang, precompiled;
    lang = {};
    precompiled = {};
    return {
      defaultInterpolator: stringInterpolator(),
      load: function(langDefinition) {
        var key, langName, setOfValues, value, _results;
        _results = [];
        for (langName in langDefinition) {
          setOfValues = langDefinition[langName];
          lang[langName] || (lang[langName] = {});
          _results.push((function() {
            var _results1;
            _results1 = [];
            for (key in setOfValues) {
              value = setOfValues[key];
              if (key === "_pluralize") {
                _results1.push(pluralization.updatePluralization(langName, setOfValues._pluralize, setOfValues._normalize));
              } else if (key === "_normalize") {

              } else {
                _results1.push(lang[langName][key] = value);
              }
            }
            return _results1;
          })());
        }
        return _results;
      },
      translate: function() {
        var args, key, language;
        language = arguments[0], key = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
        return this._apply.apply(this, [language, key].concat(__slice.call(args)));
      },
      canTranslate: function(language, key) {
        var _ref1;
        return ((_ref1 = lang[language]) != null ? _ref1[key] : void 0) !== void 0;
      },
      canTranslateTo: function(language) {
        return lang[language] !== void 0;
      },
      compile: function(language, pattern) {
        var p;
        if (pattern.key) {
          p = this._precompiled(language, pattern.key);
        } else {
          p = precompile(pattern, this._parsers(language));
        }
        return this._applier(p);
      },
      debug: function(str, lang) {
        if (lang == null) {
          lang = "en";
        }
        return this.compile(lang, str).apply({
          begin: function() {
            return console.log("{");
          },
          argument: function(ctx, _arg) {
            var argName;
            argName = _arg.argName;
            return console.log("  arg: " + argName);
          },
          pluralExpression: function(ctx, _arg, _arg1) {
            var argName, suffixes, word;
            word = _arg.word, suffixes = _arg.suffixes;
            argName = _arg1.argName;
            return console.log("  plural: " + word + "(" + suffixes + "):" + argName);
          },
          string: function(ctx, str) {
            return console.log("  '" + str + "'");
          },
          end: function() {
            return console.log("}");
          }
        });
      },
      _applier: function(precompiled) {
        var fn,
          _this = this;
        fn = function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return precompiled.apply(args, _this.defaultInterpolator);
        };
        fn.apply = function() {
          var args, interpolator;
          interpolator = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          return precompiled.apply(args, interpolator);
        };
        return fn;
      },
      _precompiled: function(language, key) {
        var _ref1, _ref2;
        return (_ref1 = (_ref2 = precompiled[language]) != null ? _ref2[key] : void 0) != null ? _ref1 : this._precompile(language, key);
      },
      _parsers: function(language) {
        return [
          argumentParser(), pluralizerParser(function(word, suffixes) {
            return pluralization.preparePluralizationFn(language, word, suffixes);
          })
        ];
      },
      _precompile: function(language, key) {
        precompiled[language] || (precompiled[language] = {});
        if (!precompiled[language]._parsers) {
          precompiled[language]._parsers = this._parsers(language);
        }
        return precompiled[language][key] = precompile(this._get(language, key), precompiled[language]._parsers);
      },
      _apply: function() {
        var args, key, language;
        language = arguments[0], key = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
        return this._precompiled(language, key).apply(args, this.defaultInterpolator);
      },
      _get: function(language, key) {
        var val;
        if (!lang[language]) {
          throw new Error("Language '" + language + "' was not initialized with 'load' method");
        }
        val = lang[language][key];
        if (!val) {
          throw new Error("There is no definition for '" + key + "' in language '" + language + "'");
        }
        return val;
      }
    };
  };

  notEmpty = function(str) {
    return str.length > 0;
  };

  precompile = function(text, parsers) {
    var ctx, currentPos, isEnd, nearestPosition, parser, parserIdx, part, positions, remaining, substr, _ref1;
    ctx = {
      parts: []
    };
    currentPos = 0;
    positions = parsers.map(function(p) {
      return p.nextPosition(text, 0);
    });
    isEnd = function() {
      return positions.every(function(pos) {
        return pos === -1;
      });
    };
    while (!(isEnd())) {
      nearestPosition = Math.min.apply(null, positions.filter(function(p) {
        return p > -1;
      }));
      parserIdx = positions.indexOf(nearestPosition);
      parser = parsers[parserIdx];
      substr = text.substring(currentPos, nearestPosition);
      if (notEmpty(substr)) {
        ctx.parts.push(justText(substr));
      }
      _ref1 = parser.process(text, nearestPosition, ctx), part = _ref1.part, currentPos = _ref1.currentPos;
      ctx.parts.push(part);
      positions.forEach(function(pos, idx) {
        if (pos < currentPos) {
          return positions[idx] = parsers[idx].nextPosition(text, currentPos);
        }
      });
    }
    remaining = text.substring(currentPos);
    if (notEmpty(remaining)) {
      ctx.parts.push(justText(remaining));
    }
    ctx.parts.forEach(function(part, idx) {
      if (part.link) {
        return part.link(ctx, idx);
      }
    });
    return {
      apply: function(args, interpolator) {
        return context(args, interpolator).apply(function(context) {
          return (ctx.parts.map(function(p) {
            return p.apply(context);
          })).join("");
        });
      }
    };
  };

}).call(this);

},{"./compile/context":2,"./compile/parsers":3,"./interpolators":5,"./pluralization":7}],5:[function(require,module,exports){
(function() {
  var stringInterpolator;

  stringInterpolator = function() {
    return {
      begin: function(context) {},
      string: function(context, str) {
        return str;
      },
      argument: function(context, _arg) {
        var argName, val;
        argName = _arg.argName;
        val = context.attrs[argName];
        if (typeof val === 'function') {
          return val();
        } else {
          return val;
        }
      },
      pluralExpression: function(context, _arg, argument) {
        var fn;
        fn = _arg.fn;
        return fn(argument.apply(context));
      },
      end: function(context) {}
    };
  };

  module.exports = {
    stringInterpolator: stringInterpolator
  };

}).call(this);

},{}],6:[function(require,module,exports){
(function() {
  var checkAttribute;

  checkAttribute = function(attribute, cbOnEmpty) {
    if (cbOnEmpty == null) {
      cbOnEmpty = function() {};
    }
    if (attribute === void 0 || attribute.trim().length === 0) {
      cbOnEmpty();
      return void 0;
    }
    return attribute;
  };

  module.exports = {
    textToKey: function(text, options) {
      if (options == null) {
        options = {
          wordsLimitForKey: 10,
          replaceSpaces: false
        };
      }
      if (!text) {
        return void 0;
      }
      return text.split(/\s+/).slice(0, options.wordsLimitForKey).join(options.replaceSpaces ? options.replaceSpaces : " ");
    },
    toKey: function(attribute, text, options) {
      var _ref;
      if (options == null) {
        options = {
          textAsKey: 'nokey'
        };
      }
      switch (options.textAsKey) {
        case true:
        case "always":
          return this.textToKey(text, options);
        case false:
        case "never":
          return checkAttribute(attribute, function() {
            throw new Error("Mandatory key attribute is not defined");
          });
        case "nokey":
          return (_ref = checkAttribute(attribute)) != null ? _ref : this.textToKey(text, options);
        default:
          throw new Error("Unknown option '" + options.textAsKey + "', possible values: 'never', 'always', 'nokey'");
      }
    }
  };

}).call(this);

},{}],7:[function(require,module,exports){
(function() {
  var normalizationForms, pluralizationForms;

  pluralizationForms = [
    {
      plural: function(n) {
        return (n > 1) ? 1 : 0;
      },
      languages: ['ach', 'ak', 'am', 'arn', 'br', 'fil', 'fr', 'gun', 'ln', 'mfe', 'mg', 'mi', 'oc', 'pt_BR', 'tg', 'ti', 'tr', 'uz', 'wa', 'zh']
    }, {
      plural: function(n) {
        return (n != 1) ? 1 : 0;
      },
      languages: ['af', 'an', 'ast', 'az', 'bg', 'bn', 'brx', 'ca', 'da', 'de', 'doi', 'el', 'en', 'eo', 'es', 'es_AR', 'et', 'eu', 'ff', 'fi', 'fo', 'fur', 'fy', 'gl', 'gu', 'ha', 'he', 'hi', 'hne', 'hy', 'hu', 'ia', 'it', 'kn', 'ku', 'lb', 'mai', 'ml', 'mn', 'mni', 'mr', 'nah', 'nap', 'nb', 'ne', 'nl', 'se', 'nn', 'no', 'nso', 'or', 'ps', 'pa', 'pap', 'pms', 'pt', 'rm', 'rw', 'sat', 'sco', 'sd', 'si', 'so', 'son', 'sq', 'sw', 'sv', 'ta', 'te', 'tk', 'ur', 'yo']
    }, {
      plural: function(n) {
        return (n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5);
      },
      languages: ['ar']
    }, {
      plural: function(n) {
        return 0;
      },
      languages: ['ay', 'bo', 'cgg', 'dz', 'fa', 'id', 'ja', 'jbo', 'ka', 'kk', 'km', 'ko', 'ky', 'lo', 'ms', 'my', 'sah', 'su', 'th', 'tt', 'ug', 'vi', 'wo', 'zh']
    }, {
      plural: function(n) {
        return (n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);
      },
      languages: ['be', 'bs', 'hr', 'ru', 'sr', 'uk']
    }, {
      plural: function(n) {
        return (n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2;
      },
      languages: ['cs', 'sk']
    }, {
      plural: function(n) {
        return n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;
      },
      languages: ['csb']
    }, {
      plural: function(n) {
        return (n==1) ? 0 : (n==2) ? 1 : (n != 8 && n != 11) ? 2 : 3;
      },
      languages: ['cy']
    }, {
      plural: function(n) {
        return n==1 ? 0 : n==2 ? 1 : n<7 ? 2 : n<11 ? 3 : 4;
      },
      languages: ['ga']
    }, {
      plural: function(n) {
        return (n==1 || n==11) ? 0 : (n==2 || n==12) ? 1 : (n > 2 && n < 20) ? 2 : 3;
      },
      languages: ['gd']
    }, {
      plural: function(n) {
        return (n%10!=1 || n%100==11) ? 1 : 0;
      },
      languages: ['is']
    }, {
      plural: function(n) {
        return (n != 0) ? 1 : 0;
      },
      languages: ['jv']
    }, {
      plural: function(n) {
        return (n==1) ? 0 : (n==2) ? 1 : (n == 3) ? 2 : 3;
      },
      languages: ['kw']
    }, {
      plural: function(n) {
        return (n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2);
      },
      languages: ['lt']
    }, {
      plural: function(n) {
        return (n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2);
      },
      languages: ['lv']
    }, {
      plural: function(n) {
        return n==1 || n%10==1 ? 0 : 1;
      },
      languages: ['mk']
    }, {
      plural: function(n) {
        return (n==0 ? 0 : n==1 ? 1 : 2);
      },
      languages: ['mnk']
    }, {
      plural: function(n) {
        return (n==1 ? 0 : n==0 || ( n%100>1 && n%100<11) ? 1 : (n%100>10 && n%100<20 ) ? 2 : 3);
      },
      languages: ['mt']
    }, {
      plural: function(n) {
        return (n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);
      },
      languages: ['pl']
    }, {
      plural: function(n) {
        return (n==1 ? 0 : (n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2);
      },
      languages: ['ro']
    }, {
      plural: function(n) {
        return (n%100==1 ? 1 : n%100==2 ? 2 : n%100==3 || n%100==4 ? 3 : 0);
      },
      languages: ['sl']
    }
  ];

  normalizationForms = {
    en: function(word, suffixes) {
      return {
        word: word,
        suffixes: (function() {
          switch (suffixes.length) {
            case 1:
              return ["", suffixes[0]];
            default:
              return suffixes;
          }
        })()
      };
    },
    ru: function(word, suffixes) {
      var form2Suffix, singularSuffix;
      switch (suffixes.length) {
        case 1:
          return {
            word: word,
            suffixes: ["", suffixes[0], ""]
          };
        case 2:
          form2Suffix = suffixes[1];
          singularSuffix = word.slice(-form2Suffix.length);
          return {
            word: word.slice(0, -singularSuffix.length),
            suffixes: [singularSuffix].concat(suffixes)
          };
        default:
          return {
            word: word,
            suffixes: suffixes
          };
      }
    }
  };

  module.exports = function() {
    var form, lang, pluralizationRules, _i, _j, _len, _len1, _ref;
    pluralizationRules = {};
    for (_i = 0, _len = pluralizationForms.length; _i < _len; _i++) {
      form = pluralizationForms[_i];
      _ref = form.languages;
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        lang = _ref[_j];
        pluralizationRules[lang] = {
          pluralize: form.plural,
          normalize: normalizationForms[lang]
        };
      }
    }
    return {
      _get: function(language, options) {
        if (options == null) {
          options = {
            useEnglishAsDefault: true
          };
        }
        if (!pluralizationRules[language] && options.useEnglishAsDefault) {
          language = "en";
        }
        return pluralizationRules[language];
      },
      getPluralizeForm: function(language, value, options) {
        return this._get(language, options).pluralize(value);
      },
      normalizeForms: function(language, word, suffixes, options) {
        var _ref1;
        return ((_ref1 = this._get(language, options).normalize) != null ? _ref1 : this._doNotNormalize)(word, suffixes);
      },
      updatePluralization: function(language, pluralizeFn, normalizeFn) {
        return pluralizationRules[language] = {
          pluralize: pluralizeFn,
          normalize: normalizeFn
        };
      },
      _doNotNormalize: function(word, suffixes) {
        return {
          word: word,
          suffixes: suffixes
        };
      },
      preparePluralizationFn: function(language, word, suffixes, options) {
        var res,
          _this = this;
        res = this.normalizeForms(language, word, suffixes, options);
        return function(val) {
          return res.word + res.suffixes[_this.getPluralizeForm(language, val, options)];
        };
      },
      getLanguages: function() {
        return Object.keys(pluralizationRules);
      },
      getAll: function() {
        return pluralizationRules;
      }
    };
  };

}).call(this);

},{}],8:[function(require,module,exports){
(function() {
  module.exports = {
    onlyMarked: true,
    textAsKey: "nokey",
    wordsLimitForKey: 10,
    replaceSpaces: false,
    generateSettingsFile: "settings.js"
  };

}).call(this);

},{}]},{},[4,1])
;