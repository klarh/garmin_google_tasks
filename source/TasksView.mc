using Toybox.Communications;
using Toybox.System;
using Toybox.WatchUi;

const TaskUrl1 = "https://www.googleapis.com/tasks/v1/lists/";
const TaskUrl2 = "/tasks/";

class ListTasksRequest extends Request {
    var app;
    var loading_view;
    var list_name;
    var list_id;

    function initialize(app, loading_view, list_name, list_id) {
        Request.initialize();
        self.app = app;
        self.loading_view = loading_view;
        self.list_name = list_name;
        self.list_id = list_id;
    }

    function request(access_token, callback) {
        var params = {
            "access_token" => access_token,
            "maxResults" => 100,
            "showCompleted" => "True",
            /* "showHidden" => "True", */
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        var url = $.TaskUrl1 + self.list_id + $.TaskUrl2;

        Communications.makeWebRequest(
            url, params, options, callback);
    }

    function run(returnCode, data) {
        var task_items = data["items"];

        var view = new TasksView(self.list_name);

        for(var i = 0; i < task_items.size(); i++) {
            var item = task_items[i];
            view.addItem(
                item["title"], item["notes"], item["id"],
                "completed".equals(item["status"]));
        }

        if(self.loading_view.stillAlive() && self.loading_view.get().is_visible) {
            WatchUi.switchToView(
                view, new TasksDelegate(self.app, self.list_id), WatchUi.SLIDE_LEFT);
        }
        else {
            WatchUi.pushView(
                view, new TasksDelegate(self.app, self.list_id), WatchUi.SLIDE_LEFT);
        }
    }
}

class CheckTaskRequest extends Request {
    var task_data;
    var list_id;
    var task_id;

    function initialize(list_id, task_id) {
        Request.initialize();
        self.task_data = null;
        self.list_id = list_id;
        self.task_id = task_id;
    }

    function request(access_token, callback) {
        if(self.task_data == null) {
            var params = {
                "access_token" => access_token,
            };

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            };

            var url = $.TaskUrl1 + self.list_id + $.TaskUrl2 + self.task_id;

            Communications.makeWebRequest(
                url, params, options, callback);
        }
        else {
            var bearer = "Bearer " + access_token;

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => bearer,
                },
            };

            var url = $.TaskUrl1 + self.list_id + $.TaskUrl2 + self.task_id;

            Communications.makeWebRequest(
                url, self.task_data, options, callback);
        }
    }

    function run(returnCode, data) {
        if("completed".equals(data["status"])) {
            data["status"] = "needsAction";
        }
        else {
            data["status"] = "completed";
        }

        self.task_data = data;
    }
}

class TasksDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    var list_id;

    function initialize(app, list_id) {
        Menu2InputDelegate.initialize();
        self.app = app;
        self.list_id = list_id;
    }

    function onSelect(item) {
        self.app.get().toggleTask(self.list_id, item.getId());
    }
}

class TasksView extends WatchUi.CheckboxMenu {
    function initialize(list_name) {
        CheckboxMenu.initialize({:title => list_name});
    }

    function addItem(title, note, id, check) {
        return CheckboxMenu.addItem(
            new WatchUi.CheckboxMenuItem(
                title, note, id, check, {}));
    }
}
