[![Build Status](https://travis-ci.org/AlexeyGrishin/granula.png?branch=master)](https://travis-ci.org/AlexeyGrishin/granula)

Introduction
-----------
__granula__ is a tool which helps with i18n of angular.js applications.

See an example on jsfiddle: http://jsfiddle.net/GRaAL/EasQP/1/

How to use
-----------

### Simple way (for small apps)
1. Get latest build from github (https://raw.github.com/AlexeyGrishin/granula/master/build/angularjs/granula.js). Sorry, will add bower component soon :(
2. In your application add `granula` to the module dependencies ```angular.module('app', ['granula'])```
3. In your HTML markup the text you'd like to translate with 'gr-key' attribute

    `<p gr-key='exact-key'>Would you like to continue?</p><button gr-key>Yes</button>`

    Note that value of 'gr-key' attribute is used as translation key. If value is not specified then text itself will be used ('Yes' in example above)
4. Create json with translation for languages you need, like this.
    
        {
          "exact-key": "Хотите продолжить?",
          "Yes": "Да"
        }

5. Put it into separate file OR directly onto the page in `<script>` tag

        <script type='granula/lang' src='ru.json' gr-lang='ru'></script>
        <!-- OR -->
        <script type='granula/lang' gr-lang='it'>
            <!-- your json -->
        </script>

    Note that script tag shall be inside tag marked with ng-app, otherwise angular will not process it (and granula as well).

### Complex way (for big apps)
1. Steps 1-3 from Simple Way
2. ``npm install -g granula```
3. Create file called ```Granulafile``` in your project root and fill it following way:

        {
          "src": "src/html",
          "out": "src/html/lang",
          "languages": "ru,it,ua,fr"
        }

4. Run `granula` in the directory with Granulafile
5. __granula__ will process your HTMLs, collect all keys (even not defined explicitly) and prepare json files in 'out' directory for all provided languages.
6. Then you may edit these files. On the next run __granula__ will add new keys to the file and mark absent ones as deleted but will not delete anything.


Features
----------
### Simplified pluralization expressions

For tags marked with 'gr-key' __granula__ automatically parses 'pluralization expressions' like the following ones:
- `{{n}} task(s)` ==> `1 task` / `2 tasks`
  - any expression with () is considered as 'pluralization expression'
  - it automatically binds to the nearest angular expression to the left
- `There (is,are):> {{n}} task(s)` ==> `There is 1 task` / `There are 2 tasks`
  - in case you provide `:>` after right parenthesis then it will be bound to the nearest angular expression to the right
- `Empty file(s):empty.length found. (It,They):empty.length will be deleted` ==> `Empty file found. It will be deleted` / `Empty files found. They will be deleted`
  - if you'd like to pluralize text over expression not used in text then just provide it after `:`. Note: you cannot use complex angular expressions and filters here, just variable names.
- `It is good \(or not)`
  - for non-pluralization expressions you may escape your parenthesis
- `У нас {{n}} кош(ка,ки,ек)` ==> `У нас 1 кошка` / `У нас 2 кошки` / `У нас 6 кошек`
  - works with other languages as well. Just provide as many suffixes in parenthesis how many pluralization forms exists in the language

### Translation of attributes

1. You need to provide list of attributes in 'gr-attrs' attribute

        <input gr-attrs='placeholder,title' title='Enter your first name' placeholder='First name'/>

2. Then, if you'd like to, you may provide exact key names with 'gr-key-{attr}' attribute. If you do not do it then attribute text will be used as key in translation.

        <input gr-attrs='placeholder,title' 
          title='Enter your first name' gr-key-title='first-name-title'
          placeholder='First name' gr-key-placeholder='first-name-placeholder'/>


Roadmap
----------------
1. Collect keys from js files as well
2. More documentation and examples
