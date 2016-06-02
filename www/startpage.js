var startpage = function() {};

startpage.prototype.loadContentSrc = function () {
    cordova.exec(function(){}, function(){}, "StartPagePlugin", "loadContentSrc", []);
};

startpage.prototype.loadStartPage = function () {
    cordova.exec(function(){}, function(){}, "StartPagePlugin", "loadStartPage", []);
};

startpage.prototype.setStartPageUrl = function (url, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "StartPagePlugin", "setStartPageUrl", [url]);
};

startpage.prototype.resetStartPageToContentSrc = function (successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "StartPagePlugin", "resetStartPageToContentSrc", []);
};

if (!window.plugins) {
    window.plugins = {};
}
if (!window.plugins.startpage) {
    window.plugins.startpage = new startpage();
}
if (typeof module != 'undefined' && module.exports) {
    module.exports = new startpage();
}
