using Toybox.Application;
using Toybox.Communications;
using Toybox.Cryptography;
using Toybox.StringUtil;
using Toybox.System;
using Toybox.WatchUi;

const AuthUrl = "https://accounts.google.com/o/oauth2/v2/auth";
const TokenUrl = "https://oauth2.googleapis.com/token";
const TaskListUrl = "https://www.googleapis.com/tasks/v1/users/@me/lists";
const TaskUrl1 = "https://www.googleapis.com/tasks/v1/lists/";
const TaskUrl2 = "/tasks/";
const RedirectUri = "urn:ietf:wg:oauth:2.0:oob";
const UserTokenId = "api_token";
const LastUserTokenId = "previous_user_token";
const RefreshToken = "google_refresh_token";
const HashSalt = "Google Tasks watch app; klarh7+garmin_dev@gmail.com";

class TaskAuthenticator {
    var client_id;
    var client_secret;

    var access_token;
    var pending_operation;

    var parent_app;
    var last_list_id;
    var last_list_name;
    var last_task_id;
    var last_error_code = null;

    function initialize(parent_app) {
        self.pending_operation = null;
        self.parent_app = parent_app;
        self.last_list_id = "";
        self.last_list_name = "";
        self.access_token = "";

        var client_json = WatchUi.loadResource(Rez.JsonData.GoogleClient)["installed"];
        self.client_id = client_json["client_id"];
        self.client_secret = client_json["client_secret"];

        var user_token = Application.Properties.getValue($.UserTokenId);
        var last_user_token = Application.Storage.getValue($.LastUserTokenId);

        // System.println("intialize, comparison:");
        // System.println(user_token);
        // System.println(last_user_token);
        if(user_token != null && !user_token.equals(last_user_token)) {
            // System.println("(clearing refresh token)");
            Application.Storage.setValue($.LastUserTokenId, user_token);
            Application.Storage.setValue($.RefreshToken, "");
        }
    }

    function getCodeVerifier() {
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
        // System.println("initialAuth");
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
        // System.println("requestToken");
        WatchUi.switchToView(
            new LoadingView(null), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_IMMEDIATE);

        var params = {
            "client_id" => self.client_id,
            "client_secret" => self.client_secret,
            /* "code_verifier" => self.getCodeVerifier(), */
        };

        var refresh_token = Application.Storage.getValue($.RefreshToken);
        // System.println("refresh token:");
        // System.println(refresh_token);
        if(refresh_token != null && refresh_token.length() > 0) {
            params["refresh_token"] = refresh_token;
            params["grant_type"] = "refresh_token";
        }
        else {
            params["code"] = Application.Properties.getValue($.UserTokenId);
            params["grant_type"] = "authorization_code";
            params["redirect_uri"] = $.RedirectUri;
        }

        // System.println("------- requestToken");
        // System.println(params);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            $.TokenUrl, params, options, method(:tokenCallback));
    }

    function tokenCallback(responseCode, data) {
        // System.println("------- tokenCallback");
        // System.println(responseCode);
        // System.println(data);

        if(responseCode == 200) {
            self.access_token = data["access_token"];

            var refresh_token = data["refresh_token"];
            if(refresh_token != null && refresh_token.length() > 0) {
                Application.Storage.setValue($.RefreshToken, refresh_token);
            }

            if(self.pending_operation != null) {
                var todo = self.pending_operation;
                self.pending_operation = null;
                todo.invoke();
            }
        }
        else if(self.last_error_code == responseCode) {
            self.handleHTTPError(responseCode, data, null);
        }
        else if(responseCode == 401) {
            initialAuth();
        }
        else if(responseCode == 400) {
            self.requestToken();
        }
        else {
            self.handleHTTPError(responseCode, data, self.pending_operation);
        }
        self.last_error_code = responseCode;
    }

    function getTaskLists() {
        // System.println("getTaskLists");
        if(!self.checkAccessToken(method(:getTaskLists))) {
            return;
        }

        var params = {
            "access_token" => self.access_token,
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            $.TaskListUrl, params, options, method(:getTaskListsCallback));
    }

    function getTaskListsCallback(responseCode, data) {
        // System.println("getTaskListsCallback");
        if(responseCode == 200) {
            var task_list = data["items"];
            var task_list_names = [];
            var task_list_ids = [];

            for(var i = 0; i < task_list.size(); i++) {
                var item = task_list[i];
                task_list_names.add(item["title"]);
                task_list_ids.add(item["id"]);
            }

            WatchUi.switchToView(
                new TaskListView(task_list_names, task_list_ids),
                new TaskListDelegate(self.weak()), WatchUi.SLIDE_IMMEDIATE);
        }
        else {
            self.handleHTTPError(responseCode, data, method(:getTaskLists));
        }
    }

    function retryListTasks() {
        // System.println("retryListTasks");
        self.listTasks(self.last_list_id, self.last_list_name);
    }

    function listTasks(list_id, list_name) {
        // System.println("listTasks");
        self.last_list_id = list_id;
        self.last_list_name = list_name;

        var params = {
            "access_token" => self.access_token,
            "maxResults" => 100,
            "showCompleted" => "True",
            /* "showHidden" => "True", */
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        var url = $.TaskUrl1 + list_id + $.TaskUrl2;

        Communications.makeWebRequest(
            url, params, options, method(:listTasksCallback));
    }

    function listTasksCallback(responseCode, data) {
        // System.println("listTasksCallback");
        if(responseCode == 200) {
            var task_items = data["items"];
            var task_titles = [];
            var task_notes = [];
            var task_ids = [];
            var task_checks = [];

            for(var i = 0; i < task_items.size(); i++) {
                var item = task_items[i];
                task_titles.add(item["title"]);
                task_notes.add(item["notes"]);
                task_ids.add(item["id"]);
                task_checks.add("completed".equals(item["status"]));
            }

            var view = new TasksView(
                task_titles, task_notes, task_ids, task_checks, self.last_list_name);
            WatchUi.pushView(
                view, new TasksDelegate(self.weak()), WatchUi.SLIDE_IMMEDIATE);
        }
        else {
            self.handleHTTPError(responseCode, data, method(:retryListTasks));
        }
    }

    function retryToggleTask() {
        // System.println("retryToggleTask");
        self.toggleTask(self.last_task_id);
    }

    function toggleTask(task_id) {
        // System.println("toggleTask");
        self.last_task_id = task_id;

        var params = {
            "access_token" => self.access_token,
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        var url = $.TaskUrl1 + self.last_list_id + $.TaskUrl2 + task_id;

        Communications.makeWebRequest(
            url, params, options, method(:toggleTaskCallback1));
    }

    function toggleTaskCallback1(responseCode, data) {
        // System.println("toggleTaskCallback1");
        // System.println(responseCode);
        // System.println(data);
        if(responseCode == 200) {
            var bearer = "Bearer " + self.access_token;

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => bearer,
                },
            };

            if("completed".equals(data["status"])) {
                data["status"] = "needsAction";
            }
            else {
                data["status"] = "completed";
            }

            var url = $.TaskUrl1 + self.last_list_id + $.TaskUrl2 + self.last_task_id;

            Communications.makeWebRequest(
                url, data, options, method(:toggleTaskCallback2));
        }
        else {
            self.handleHTTPError(responseCode, data, method(:retryToggleTask));
        }
    }

    function toggleTaskCallback2(responseCode, data) {
        // System.println("toggleTaskCallback2");
        // System.println(responseCode);
        // System.println(data);
        if(responseCode != 200) {
            self.handleHTTPError(responseCode, data, method(:retryToggleTask));
        }
    }

    function handleHTTPError(responseCode, data, pending_operation) {
        // System.println("handleHTTPError");
        self.pending_operation = pending_operation;

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
        // System.println("onSettingsChanged");
        var user_token = Application.Properties.getValue($.UserTokenId);
        var last_user_token = Application.Storage.getValue($.LastUserTokenId);

        // System.println("onSettingsChanged, comparison:");
        // System.println(user_token);
        // System.println(last_user_token);
        if(user_token != null && !user_token.equals(last_user_token)) {
            Application.Storage.setValue($.LastUserTokenId, user_token);
            Application.Storage.setValue($.RefreshToken, "");
            // System.println("(clearing refresh token)");
            self.getTaskLists();
        }
    }

    function checkAccessToken(retry_callback) {
        // System.println("checkAccessToken");
        var user_token = Application.Properties.getValue($.UserTokenId);
        if(user_token == null || user_token.length() <= 0) {
            // System.println("user_token path");
            self.initialAuth();
            return false;
        }
        else if(self.access_token == null || self.access_token.length() <= 0) {
            // System.println("access_token path");
            self.pending_operation = retry_callback;
            self.requestToken();
            return false;
        }

        return true;
    }
}
