var DefaultRenderer, Doxdown, Fs, Path, Str, between, langMarkers, removeLangMarkers, updatePartials;

DefaultRenderer = require("./defaultRenderer");

Doxdown = require("./doxdown");

Path = require("path");

Fs = require("fs");

Str = require('underscore.string');

between = function(s, startToken, endToken) {
  var endPos, start, startPos;
  startPos = s.indexOf(startToken);
  if (startPos < 0) {
    return "";
  }
  endPos = s.indexOf(endToken, startPos);
  start = startPos + startToken.length;
  if (endPos > startPos) {
    return s.slice(start, endPos);
  } else {
    return "";
  }
};

langMarkers = {
  js: ['//{{{ Content ', '//}}}'],
  coffee: ['#{{{ Content ', '#}}}']
};

removeLangMarkers = function(s) {
  return s.replace(/\n?^.*{{{ Content.*$/mg, '').replace(/\n^.*}}}.*$/mg, '');
};

updatePartials = function(assets, markdown, root) {
  if (markdown.indexOf(':::#') >= 0) {
    markdown = markdown.replace(/\s*:::#.*/g, '');
  }
  if (markdown.indexOf(':::<') >= 0) {
    markdown = markdown.replace(/:::< (.*)/g, function(found) {
      var arg, args, argv, assetName, block, clean, file, filename, hide, i, lang, leftMarker, noCapture, raw, result, rightMarker, tabName, text, _i, _len, _ref, _ref1;
      args = found.substring(4).trim().split(' ');
      filename = args[0];
      if (filename.indexOf('#')) {
        _ref = filename.split('#'), filename = _ref[0], block = _ref[1];
      }
      noCapture = false;
      for (i = _i = 0, _len = args.length; _i < _len; i = ++_i) {
        arg = args[i];
        switch (arg) {
          case '--no-capture':
            noCapture = true;
            break;
          case '--block':
            block = args[i + 1];
            break;
          case '--lang':
            lang = args[i + 1];
            break;
          case '--as-tab':
            tabName = args[i + 1];
            break;
          case '--raw':
            raw = true;
            break;
          case '--hide':
            hide = true;
            break;
          case '--clean':
            clean = true;
            break;
          case '--as-asset':
            clean = true;
            noCapture = true;
            assetName = Path.basename(args[i + 1]);
            break;
          default:
            if (arg.indexOf('--') === 0) {
              throw new Error("Unrecognized :::< option: " + arg);
            } else {
              continue;
            }
        }
      }
      if (!lang) {
        lang = Path.extname(filename);
        if (lang[0] === '.') {
          lang = lang.slice(1);
        } else {
          console.log('Cannot determine lang from extension and `--lang` not used');
          return found;
        }
      }
      file = Path.resolve(Path.join(root, filename));
      if (Fs.existsSync(file)) {
        text = Fs.readFileSync(file, 'utf8');
        if (raw) {
          return text;
        }
        if (clean) {
          text = removeLangMarkers(text);
        }
        if (assetName) {
          assets[assetName] = text;
        }
        if (tabName) {
          assets[tabName] = text;
          return "";
        } else {
          if (block) {
            _ref1 = langMarkers[lang], leftMarker = _ref1[0], rightMarker = _ref1[1];
            if (text.indexOf(leftMarker + block) >= 0) {
              text = between(text, leftMarker + block, rightMarker);
              text = Str.trim(text, '\r\n');
            }
          }
          result = "";
          argv = [];
          if (noCapture) {
            argv.push('--no-capture');
          }
          if (hide) {
            argv.push('--hide');
          }
          if (argv.length > 0) {
            result += ":::@ " + (argv.join(' ')) + "\n\n";
          }
          if (assetName) {
            result += ":::@ --hide\n\n```html\n<script src='" + assetName + "'></script>\n```";
          } else {
            result += "```" + lang + "\n" + text + "\n```";
          }
          return result;
        }
      } else {
        return found;
      }
    });
  }
  return markdown;
};

module.exports = {
  /*
  * Renders markdown to HTML.
  * @param  {String}   markdown The markdown to convert.
  * @param  {Object}   options  = {
  *   {String} assetsDirname       Where to write assets.
  *   {String} docStylesheetFile   Stylesheet file path.
  *   {String} docScriptFile       Script file path.
  *   {String} docLayoutFile       Layout file path.
  *   {String} exampleLayoutFile   Example layout path.
  * }
  * @param  {Function} cb       function(err, html)
  */

  render: function(markdown, options, cb) {
    var renderer;
    options.userAssets = {};
    renderer = new DefaultRenderer(options);
    markdown = updatePartials(options.userAssets, markdown, Path.dirname(options.filename));
    return renderer.render(markdown, cb);
  },
  /*
  * Renders javascript/coffee to HTML API docs.
  */

  renderApi: function(source, options, cb) {
    return Doxdown.render(source, options, cb);
  }
};


/*
//@ sourceMappingURL=index.map
*/