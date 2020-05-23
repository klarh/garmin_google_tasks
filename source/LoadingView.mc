using Toybox.WatchUi;

class LoadingView extends WatchUi.View {
    var task_authenticator;

    function initialize(task_authenticator) {
        View.initialize();
        self.task_authenticator = task_authenticator;
    }

    function onShow() {
        if(self.task_authenticator != null) {
            self.task_authenticator.getTaskLists();
        }
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.LoadingScreen(dc));
    }
}
