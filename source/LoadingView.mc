using Toybox.WatchUi;

class LoadingView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onShow() {
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.LoadingScreen(dc));
    }
}
