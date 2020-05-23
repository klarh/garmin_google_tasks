using Toybox.WatchUi;

class ErrorView extends WatchUi.View {
    var code;
    var data;

    function initialize(code, data) {
        self.code = code;
        self.data = data;

        View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.ErrorScreen(dc));

        var code_label = View.findDrawableById("error_code");
        code_label.setText(self.code.toString());
        var data_label = View.findDrawableById("error_text");
        data_label.setText(self.data.toString());
    }
}
