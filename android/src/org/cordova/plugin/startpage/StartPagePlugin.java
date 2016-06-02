package org.cordova.plugin.startpage;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import android.preference.PreferenceManager;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaActivity;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaPreferences;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import java.lang.reflect.Field;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class StartPagePlugin extends CordovaPlugin {

	public static final String TAG = "StartPagePlugin";
    private CordovaPreferences preferences;
    volatile private Context appContext;
    private String contentSrc;
    private boolean shouldAddVersionToUrl = false;
    private static boolean bootstrappedAlready = false;

    // From cordova's config.xml
    private final String kContentSrc = "widget.content.src";
    private final String kStartPage = "StartPage";
    private final String kIncludeVersionInStartPageUrl = "IncludeVersionInStartPageUrl";

    // in query params for start page url
    private final String kNativeVersion = "nativeVersion";
    private final String kNativeBuild = "nativeBuild";

    protected void forceLoadUrl(final String url) {
        webView.stopLoading();

        final Handler mainHandler = new Handler(cordova.getActivity().getMainLooper());
        final Looper myLooper = Looper.myLooper();
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                new Handler(myLooper).post(new Runnable() {
                    @Override
                    public void run() {
                        webView.loadUrlIntoView(url, false);
                    }
                });
            }
        });
    }

    protected void bootstrap() {
        SharedPreferences defaults = PreferenceManager.getDefaultSharedPreferences(appContext);

        // parse widget.content.src
        String contentSrc = this.contentSrc;

        // read old widget.content.src
        String oldContentSrc = defaults.getString(kContentSrc, null);

        String launchUrl = defaults.getString(kStartPage, null);
        String urlToFinallyCalculateAndLoad = null;
        if(contentSrc != null && oldContentSrc != null && launchUrl != null && contentSrc.equals(oldContentSrc)) {
            urlToFinallyCalculateAndLoad = launchUrl;
        } else {
            urlToFinallyCalculateAndLoad = contentSrc;
            defaults.edit()
                    .putString(kStartPage, contentSrc)
                    .putString(kContentSrc, contentSrc)
                    .apply();
        }

        // Check if we need to include version in the url as query params, read from config.xml
        shouldAddVersionToUrl =
                preferences.getString(kIncludeVersionInStartPageUrl, "false").equals("true");

        urlToFinallyCalculateAndLoad = addVersionToUrlIfRequired(urlToFinallyCalculateAndLoad);
        forceLoadUrl(urlToFinallyCalculateAndLoad);
    }

    protected String addVersionToUrlIfRequired(String page) {
        if(shouldAddVersionToUrl) {
            try {
                PackageInfo pInfo = appContext.getPackageManager().getPackageInfo(appContext.getPackageName(), 0);
                String queryParamPrefix =
                        (page.contains("=") && page.contains("?")) ? "&":"?";

                String nativeVersion = pInfo.versionName;
                int nativeBuild = pInfo.versionCode;

                page = String.format("%s%s%s=%s&%s=%d", page, queryParamPrefix, kNativeVersion, nativeVersion, kNativeBuild, nativeBuild);

            } catch (PackageManager.NameNotFoundException e) {
                e.printStackTrace();
            }
        }
        return page;
    }

    @Override
    public void initialize(final CordovaInterface cordova, final CordovaWebView webView) {
        super.initialize(cordova, webView);

        // Only on first load of the plugin
        if(!bootstrappedAlready) {
            bootstrappedAlready = true;
            CordovaActivity cordovaActivity = (CordovaActivity)cordova.getActivity();
            try {
                Field f = CordovaActivity.class.getDeclaredField("preferences");
                f.setAccessible(true);
                preferences = (CordovaPreferences)f.get(cordovaActivity);

                f = CordovaActivity.class.getDeclaredField("launchUrl");
                f.setAccessible(true);
                contentSrc = (String)f.get(cordovaActivity);

                appContext = cordova.getActivity().getApplicationContext();
                bootstrap();
            } catch (NoSuchFieldException e) {
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }
    }

    // Copied from Cordova's ConfigXmlParser.java setStartUrl.
    protected String finalizeUrl(String src) {
        Pattern schemeRegex = Pattern.compile("^[a-z-]+://");
        Matcher matcher = schemeRegex.matcher(src);
        if (matcher.find()) {
            return src;
        } else {
            if (src.charAt(0) == '/') {
                src = src.substring(1);
            }
            return "file:///android_asset/www/" + src;
        }
    }

    @Override
	public boolean execute(final String action, final JSONArray data, final CallbackContext callbackContext) throws JSONException {

  		if(action.equals("setStartPageUrl")){
			final String startPageUrl = data.getString(0);

            if(startPageUrl != null) {
                SharedPreferences defaults = PreferenceManager.getDefaultSharedPreferences(appContext);
                defaults.edit().putString(kStartPage,
                        finalizeUrl(startPageUrl)
                ).apply();
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
            } else {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "bad_url"));
            }

  			return true;
  		} else if(action.equals("loadStartPage")) {
            String urlContentSrc = addVersionToUrlIfRequired(PreferenceManager.getDefaultSharedPreferences(appContext).getString(contentSrc, contentSrc));
            forceLoadUrl(urlContentSrc);
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.NO_RESULT));
            return true;
		} else if(action.equals("loadContentSrc")) {
            String urlContentSrc = addVersionToUrlIfRequired(PreferenceManager.getDefaultSharedPreferences(appContext).getString(contentSrc, contentSrc));
            forceLoadUrl(urlContentSrc);
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.NO_RESULT));
            return true;
		} else if(action.equals("resetStartPageToContentSrc")) {
            SharedPreferences defaults = PreferenceManager.getDefaultSharedPreferences(appContext);
            defaults.edit().putString(kStartPage, contentSrc).apply();
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
            return true;
    }
		return false;
	}

}
