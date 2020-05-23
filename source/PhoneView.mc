using Toybox.WatchUi;

class PhoneView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.PhoneScreen(dc));
    }
}
