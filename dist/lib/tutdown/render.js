var async, beautifyCss, beautifyHtml, beautifyJs, codeFilter, fs, marked, npath, parse, renderAssets, renderMarkup, str, utils, _;

_ = require("underscore");

str = require("underscore.string");

async = require("async");

utils = require("./utils");

codeFilter = require("./codeFilter");

marked = require("marked");

fs = require("fs");

beautifyJs = require('js-beautify');

beautifyCss = require('js-beautify').css;

beautifyHtml = require('js-beautify').html;

npath = require('path');

renderAssets = function(id, assets, options, cb) {
  var assetId, assetsTemplate, codeTemplate, idOrig, iframeAttributes, layout, linkFirstTemplate, linkTemplate, outDirname, processAsset, processCapturedAsset, processUserAsset, tabDivs, tabLinks, tabTemplate, userAssets;
  layout = options.templates.example;
  iframeAttributes = options.exampleAttributes;
  userAssets = options.userAssets;
  outDirname = npath.basename(options.assetsDirname);
  idOrig = id;
  id = id.toLowerCase();
  assetId = 0;
  tabLinks = "";
  tabDivs = "";
  assetsTemplate = "<div id=\"{{{id}}}_tabs\" class=\"tabs\">\n  <ul>\n    {{{tabLinks}}}\n  </ul>\n</div>\n<div id=\"{{{id}}}_tabs_content\" class=\"tabs_content\">\n  {{{tabDivs}}}\n</div>";
  linkFirstTemplate = "<li class=\"active\">\n  <a href=\"\#{{{idname}}}-tab\" rel=\"{{{idname}}}-tab\">\n    {{{name}}}\n  </a>\n</li>";
  linkTemplate = "<li>\n  <a href=\"\#{{{idname}}}-tab\" rel=\"{{{idname}}}-tab\">\n    {{{name}}}\n  </a>\n</li>";
  tabTemplate = "<div id=\"{{{idname}}}-tab\" class=\"tab_content\">\n  {{{content}}}\n</div>";
  tabLinks = _.template(linkFirstTemplate, {
    id: id,
    name: "result",
    idname: id + "result"
  });
  tabDivs = _.template(tabTemplate, {
    id: id,
    name: "result",
    idname: str.slugify(id + "result"),
    content: "<iframe id=\"" + id + "\" src=\"" + outDirname + "/" + idOrig + ".html\" class=\"result\" " + iframeAttributes + "></iframe>"
  });
  codeTemplate = "<pre><code class=\"language-{{{lang}}}\">{{{code}}}</code></pre>";
  processAsset = function(assets, name, cb) {
    var content, idname, lang, saveResult, tabLinkTemplate;
    idname = str.slugify(id + name);
    tabLinkTemplate = tabLinks.length === 0 ? linkFirstTemplate : linkTemplate;
    tabLinks += _.template(tabLinkTemplate, {
      id: id,
      name: name,
      idname: idname
    });
    content = assets[name];
    saveResult = function(lang) {
      return function(err, result) {
        var code;
        if (err) {
          return cb(err);
        }
        code = _.template(codeTemplate, {
          code: result,
          lang: lang
        });
        tabDivs += _.template(tabTemplate, {
          id: id,
          content: code,
          name: name,
          idname: idname
        });
        return cb();
      };
    };
    if (name === "code" || str.endsWith(name, ".js")) {
      content = beautifyJs(content, {
        indent_size: 2
      });
      return content = codeFilter(content, {
        language: "js"
      }, saveResult('js'));
    } else if (name === "markup" || str.endsWith(name, ".html")) {
      content = renderMarkup(layout, id, assets);
      return content = codeFilter(content, {
        language: "html"
      }, saveResult('html'));
    } else if (name === "style" || str.endsWith(name, ".css")) {
      content = beautifyCss(content, {
        indent_size: 2
      });
      return content = codeFilter(content, {
        language: "css"
      }, saveResult("css"));
    } else {
      lang = npath.extname(name).slice(1);
      return content = codeFilter(content, {
        language: lang
      }, saveResult(lang));
    }
  };
  processCapturedAsset = function(name, cb) {
    return processAsset(assets, name, cb);
  };
  processUserAsset = function(name, cb) {
    if (name == null) {
      return cb();
    }
    return processAsset(userAssets, name, cb);
  };
  return async.forEach(Object.keys(assets), processCapturedAsset, function(err) {
    if (err) {
      return cb(err);
    }
    return async.forEach(Object.keys(userAssets), processUserAsset, function(err) {
      var result;
      if (err) {
        return cb(err);
      }
      result = _.template(assetsTemplate, {
        id: id,
        tabLinks: tabLinks,
        tabDivs: tabDivs
      });
      return cb(null, result);
    });
  });
};

renderMarkup = function(layout, id, assets) {
  var name, page, scripts, stylesheets;
  stylesheets = "";
  scripts = "";
  for (name in assets) {
    if (str.endsWith(name, ".css")) {
      stylesheets += "<link rel='stylesheet' type='text/css' href='" + id + "-" + name + "' />";
    } else if (str.endsWith(name, ".js")) {
      scripts += "<script type='text/javascript' src='" + id + "-" + name + "'></script>";
    }
  }
  return page = _.template(layout, {
    markup: assets['markup.html'],
    stylesheets: stylesheets,
    scripts: scripts
  });
};

exports.renderExample = function(section, options, cb) {
  var assets, attributes, exampleRegex, id;
  options = _.clone(options);
  id = section.id, assets = section.assets;
  exampleRegex = /^{{{EXAMPLE([^}]*)}}}/;
  attributes = "";
  _.find(section.tokens, function(tok) {
    var matches, result, _ref;
    result = false;
    if (tok.type !== 'code') {
      matches = (_ref = tok.text) != null ? _ref.match(exampleRegex) : void 0;
      if (matches) {
        attributes = matches[1];
        result = true;
      }
    }
    return result;
  });
  options.exampleAttributes = attributes;
  return renderAssets(id, assets, options, function(err, html) {
    var page, token;
    if (err) {
      return cb(err);
    }
    token = utils.rawToken(html);
    page = renderMarkup(options.templates.example, id, assets);
    return cb(null, [token, page]);
  });
};

parse = function(tokens) {
  var options;
  options = {
    gfm: true,
    tables: true,
    breaks: false,
    pedantic: false,
    sanitize: false,
    smartLists: true,
    langPrefix: ""
  };
  return marked.Parser.parse(tokens, options);
};

exports.renderTokens = function(tokens, options, cb) {
  var codeTokens, filterCode;
  options = _.clone(options);
  if (!tokens.links) {
    tokens.links = [];
  }
  codeTokens = _.filter(tokens, function(token) {
    return (token != null ? token.type : void 0) === "code";
  });
  filterCode = function(token, cb) {
    var lang, opts;
    lang = token.lang;
    opts = {
      language: lang
    };
    if (options.templates[lang] != null) {
      opts.template = options.templates[lang];
    }
    return codeFilter(token.text, opts, function(err, result) {
      if (err) {
        return cb(err);
      }
      if (_.isString(result)) {
        token.text = result;
        token.escaped = true;
      } else if (_.isObject(result)) {
        _.extend(token, result);
        token.escaped = true;
      }
      if (token.lang) {
        token.lang = token.lang.split(/\s/)[0];
      }
      return cb();
    });
  };
  return async.forEach(codeTokens, filterCode, function(err) {
    if (err) {
      return cb(err);
    }
    return cb(null, parse(tokens));
  });
};


/*
//@ sourceMappingURL=render.map
*/