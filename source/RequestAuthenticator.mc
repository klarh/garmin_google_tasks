using Toybox.Application;
using Toybox.Communications;
using Toybox.Cryptography;
using Toybox.StringUtil;
using Toybox.System;
using Toybox.WatchUi;

const AuthUrl = "https://accounts.google.com/o/oauth2/v2/auth";
const TokenUrl = "https://oauth2.googleapis.com/token";
const RedirectUri = "urn:ietf:wg:oauth:2.0:oob";
const UserTokenId = "api_token";
const LastUserTokenId = "previous_user_token";
const RefreshToken = "google_refresh_token";
const HashSalt = "Google Tasks watch app; klarh7+garmin_dev@gmail.com";

class Request {
    function initialize() {
//        System.println("initialize");
    }

    function request(access_token, callback) {
//        System.println("request");
    }

    function run(returnCode, data) {
//        System.println("run");
    }
}

class RequestAuthenticator {
    var client_id;
    var client_secret;

    var access_token;
    var pending_tasks;
    var currently_processing;

    var last_error_code = null;

    function initialize() {
//        System.println("initialize");
        self.pending_tasks = [];
        self.access_token = "";
        self.currently_processing = false;

        var client_json = WatchUi.loadResource(Rez.JsonData.GoogleClient)["installed"];
        self.client_id = client_json["client_id"];
        self.client_secret = client_json["client_secret"];

        var user_token = Application.Properties.getValue($.UserTokenId);
        var last_user_token = Application.Storage.getValue($.LastUserTokenId);

        if(user_token != null && !user_token.equals(last_user_token)) {
            Application.Storage.setValue($.LastUserTokenId, user_token);
            Application.Storage.setValue($.RefreshToken, "");
        }
    }

    function getCodeVerifier() {
//        System.println("getCodeVerifier");
        var settings = System.getDeviceSettings();
        var hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});
        var encode_options = {
            :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
            :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY};
        var decode_options = {
            :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
            :toRepresentation => StringUtil.REPRESENTATION_STRING_HEX};

        var encoded = StringUtil.convertEncodedString(
            $.HashSalt, encode_options);
        hash.update(encoded);
        encoded = StringUtil.convertEncodedString(
            settings.uniqueIdentifier, encode_options);
        hash.update(encoded);
        var decoded = StringUtil.convertEncodedString(
            hash.digest(), decode_options);
        return decoded;
    }

    function initialAuth() {
//        System.println("initialAuth");
        WatchUi.switchToView(
            new PhoneView(), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_IMMEDIATE);
//        WatchUi.requestUpdate();

        var params = {
            "client_id" => self.client_id,
            "redirect_uri" => $.RedirectUri,
            "response_type" => "code",
            "scope" => "https://www.googleapis.com/auth/tasks",
            /* "code_challenge" => self.getCodeVerifier(), */
            /* "code_challenge_method" => "plain", */
        };

        Communications.openWebPage($.AuthUrl, params, null);
    }

    function requestToken() {
//        System.println("requestToken");
        WatchUi.switchToView(
            new LoadingView(), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_IMMEDIATE);

        var params = {
            "client_id" => self.client_id,
            "client_secret" => self.client_secret,
            /* "code_verifier" => self.getCodeVerifier(), */
        };

        var refresh_token = Application.Storage.getValue($.RefreshToken);
        if(refresh_token != null && refresh_token.length() > 0) {
            params["refresh_token"] = refresh_token;
            params["grant_type"] = "refresh_token";
        }
        else {
            params["code"] = Application.Properties.getValue($.UserTokenId);
            params["grant_type"] = "authorization_code";
            params["redirect_uri"] = $.RedirectUri;
        }


        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            $.TokenUrl, params, options, method(:tokenCallback));
    }

    function tokenCallback(responseCode, data) {
//        System.println("tokenCallback");

        if(responseCode == 200) {
            self.access_token = data["access_token"];

            var refresh_token = data["refresh_token"];
            if(refresh_token != null && refresh_token.length() > 0) {
                Application.Storage.setValue($.RefreshToken, refresh_token);
            }

            self.processRequests();
        }
        else if(responseCode == 401) {
            initialAuth();
        }
        else {
            self.handleHTTPError(responseCode, data);
        }
    }

    function processRequests() {
//        System.println("processRequests");
//        System.println(self.pending_tasks.size().toString() + " " + self.currently_processing.toString());
        if(self.currently_processing) {
            return;
        }

        self.checkAccessToken();

        if(self.pending_tasks.size() > 0) {
            self.currently_processing = true;
            var task = self.pending_tasks[0];
            task.request(self.access_token, method(:processRequestsCallback));
        }
    }

    function processRequestsCallback(responseCode, data) {
//        System.println("processRequestsCallback (should always be true) " + self.currently_processing.toString());
        self.currently_processing = false;
//        System.println(self.pending_tasks.size().toString() + " " + responseCode.toString() + " " + data.toString());
        if(responseCode == 200) {
            var task = self.pending_tasks[0];
            self.pending_tasks = self.pending_tasks.slice(1, null);
            task.run(responseCode, data);
            self.processRequests();
        }
        else {
            return self.handleHTTPError(responseCode, data);
        }
    }

    function handleHTTPError(responseCode, data) {
//        System.println("handleHTTPError");
//        System.println(responseCode);
//        System.println(data);

        if(self.last_error_code == responseCode) {
            var msg = data["error"];
            if(data["error_description"] != null) {
                msg = msg + ": " + data["error_description"];
            }
            WatchUi.switchToView(
                new ErrorView(responseCode, msg), new WatchUi.BehaviorDelegate(),
                WatchUi.SLIDE_IMMEDIATE);

            var timer = new Timer.Timer();
            timer.start(method(:initialAuth), 8000, false);
        }
        else {
            self.requestToken();
        }

        self.last_error_code = responseCode;
    }

    function onSettingsChanged() {
//        System.println("onSettingsChanged");
        var user_token = Application.Properties.getValue($.UserTokenId);
        var last_user_token = Application.Storage.getValue($.LastUserTokenId);

        if(user_token != null && !user_token.equals(last_user_token)) {
            Application.Storage.setValue($.LastUserTokenId, user_token);
            Application.Storage.setValue($.RefreshToken, "");
            return true;
        }
        return false;
    }

    function checkAccessToken() {
//        System.println("checkAccessToken");
        if(self.access_token.length() > 0) {
            return true;
        }

        var user_token = Application.Properties.getValue($.UserTokenId);
        if(user_token == null || user_token.length() <= 0) {
            self.initialAuth();
            return false;
        }
        else if(self.access_token == null || self.access_token.length() <= 0) {
            self.requestToken();
            return false;
        }

        return true;
    }

    function add(request) {
//        System.println("add");
        self.pending_tasks.add(request);
    }

    function size() {
        return self.pending_tasks.size();
    }
}
