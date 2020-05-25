using Toybox.Application;
using Toybox.Time;
using Toybox.WatchUi;

class TasksApp extends Application.AppBase {
    var request_authenticator;

    function initialize() {
//        System.println("initialize");
        AppBase.initialize();
        self.request_authenticator = new RequestAuthenticator();
    }

    // onStart() is called on application start up
    function onStart(state) {
//        System.println("onStart");
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
//        System.println("onStop");
    }

    // Return the initial view of your application here
    function getInitialView() {
//        System.println("getInitialView");
        self.listTaskLists();
        return [new LoadingView("lists"), new DiceDelegate()];
    }

    function onSettingsChanged() {
//        System.println("onSettingsChanged");
        if(self.request_authenticator.onSettingsChanged()) {
            self.listTaskLists();
        }
    }

    function listTaskLists() {
//        System.println("listTaskLists");
        self.request_authenticator.add(new ListTaskListRequest(self.weak()));
        self.request_authenticator.processRequests();
    }

    function listTasks(id, label) {
//        System.println("listTasks");
        var loading_view = new LoadingView("tasks");
        WatchUi.pushView(
            loading_view, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);

        self.request_authenticator.add(
            new ListTasksRequest(self.weak(), loading_view.weak(), label, id));
        self.request_authenticator.processRequests();
    }

    function toggleTask(list_id, task_id) {
//        System.println("toggleTask");
        var request = new CheckTaskRequest(list_id, task_id);
        self.request_authenticator.add(request);
        // add twice for the two steps: grabbing the current value and
        // posting an updated value
        self.request_authenticator.add(request);
        self.request_authenticator.processRequests();
    }
}
