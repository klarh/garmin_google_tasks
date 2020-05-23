using Toybox.Application;
using Toybox.Time;
using Toybox.WatchUi;

class TasksApp extends Application.AppBase {
    var task_authenticator;

    function initialize() {
        AppBase.initialize();
        self.task_authenticator = new TaskAuthenticator(self.weak());
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [new LoadingView(self.task_authenticator), new DiceDelegate()];
    }

    function onSettingsChanged() {
        self.task_authenticator.onSettingsChanged();
    }
}
