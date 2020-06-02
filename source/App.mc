using Toybox.Application;
using Toybox.Time;
using Toybox.Timer;
using Toybox.WatchUi;

class TasksApp extends Application.AppBase {
    var request_authenticator;

    function initialize() {
        AppBase.initialize();
        self.request_authenticator = new RequestAuthenticator();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        var view = new LoadingView("lists", method(:listTaskLists));
        return [view, new WatchUi.BehaviorDelegate()];
    }

    function onSettingsChanged() {
        if(self.request_authenticator.onSettingsChanged()) {
            self.listTaskLists();
        }
    }

    function listTaskLists() {
        self.request_authenticator.add(new ListTaskListRequest(self.weak()));
        self.request_authenticator.processRequests();
    }

    function listTasks(id, label) {
        var loading_view = new LoadingView("tasks", null);
        WatchUi.pushView(
            loading_view, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);

        self.request_authenticator.add(
            new ListTasksRequest(self.weak(), loading_view.weak(), label, id));
        self.request_authenticator.processRequests();
    }

    function toggleTask(list_id, task_id) {
        self.request_authenticator.add(new CheckTaskRequest(list_id, task_id));
        self.request_authenticator.processRequests();
    }
}
