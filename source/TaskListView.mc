using Toybox.Communications;
using Toybox.System;
using Toybox.WatchUi;

const TaskListUrl = "https://www.googleapis.com/tasks/v1/users/@me/lists";

class ListTaskListRequest extends Request {
    var app;

    function initialize(app) {
        Request.initialize();
        self.app = app;
    }

    function request(access_token, callback) {
        WatchUi.switchToView(
            new LoadingView("lists", null), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_IMMEDIATE);

        var params = {
            "access_token" => access_token,
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            $.TaskListUrl, params, options, callback);
    }

    function run(returnCode, data) {
        var view = new TaskListView();

        if(returnCode == 200) {
            var task_list = data["items"];

            for(var i = 0; i < task_list.size(); i++) {
                var item = task_list[i];
                view.addItem(item["title"], item["id"]);
            }
        }

        WatchUi.switchToView(
            view, new TaskListDelegate(self.app), WatchUi.SLIDE_IMMEDIATE);
    }
}

class TaskListDelegate extends WatchUi.Menu2InputDelegate {
    var app;

    function initialize(app) {
        Menu2InputDelegate.initialize();
        self.app = app;
    }

    function onSelect(item) {
        self.app.get().listTasks(item.getId(), item.getLabel());
    }
}

class TaskListView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Tasks"});
    }

    function addItem(name, id) {
        return Menu2.addItem(new WatchUi.MenuItem(name, null, id, null));
    }
}
