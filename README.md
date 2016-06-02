# cordova-plugin-startpage
A plugin to modify the Cordova start page in run time.

This plugin let's you change the start page to different URLs, not restricted by the widget.content.src entry in config.xml
Which is static until you provide an application update.

## Usage
First, reference the plugin with:
```js
var startpage = cordova.require('org.alonamir.startpage.StartPagePlugin');
```

### To set the start page for future app boot, run
```js
startpage.setStartPageUrl('http://myUrl.com', function success(){}, function error(){});
```

### To reload the url from widget.content.src in config.xml
```js
startpage.loadContentSrc();
```

### Load the current start page (the last one you set, will fallback to widget.content.src if nothing was set)
```js
startpage.loadStartPage();
```

### Reset the start page to the one defined in widget.content.src (the usual cordova behaviour)
```js
startpage.resetStartPageToContentSrc(function success(){}, function error(){});
```
